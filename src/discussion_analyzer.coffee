request           = require "request"
config            = require "./config"
async             = require "async"
childProcess      = require "child_process"
DiscussionFetcher = require "./discussion_fetcher"

class DiscussionAnalyzer
  constructor: ->
    @_filtered = []

  start: (fn, cb) ->
    if !config.tender.siteName || !config.tender.apiKey
      throw new Error "You need to supply Tender credentials!"

    opts =
      site   : config.tender.siteName
      apiKey : config.tender.apiKey
      state  : config.state

    fetcher = new DiscussionFetcher opts
    fetcher.fetch (err, discussions) =>
      if err
        throw err

      @_filterDiscussions discussions, (err) =>
        if err
          throw err

        @_fetchStatsForDiscussions @_filtered, fn, cb

  _filterDiscussions: (discussions, cb) ->
    if discussions.length == 0
      return cb()

    q = async.queue @_filter.bind(this), 1
    q.drain = cb
    q.push discussions

  _filter: (discussion, cb) ->
    result = []

    if config.hoursAgo
      now      = +new Date
      hoursAgo = +new Date(now - (config.hoursAgo * 60 * 60 * 1000))

      thenTime = +new Date(discussion.created_at)
      if thenTime < hoursAgo
        return cb()


    # Do not consider items that already have a details comment
    @_fetchComments discussion.href, (err, result) =>
      if err
        return cb err

      hasComment = false

      for comment in result.comments
        matches = comment.internal == config.formData.internal

        matches = matches && comment.author_email == config.formData.authorEmail
        matches = matches && /^\#Script generated/.test(comment.body)

        if matches
          hasComment = true
          break

      if !hasComment
        @_filtered.push discussion

      cb()

  _fetchStatsForDiscussions: (discussions, fn, cb) ->
    if discussions.length == 0
      return cb()

    q = async.queue @_fetchStats.bind(this), 1
    q.drain = cb

    index = 1
    for d in discussions
      obj =
        index      : index++
        total      : discussions.length
        fn         : fn
        discussion : d
      q.push obj

  _fetchStats: (obj, cb) ->
    discussion = obj.discussion
    index      = obj.index
    total      = obj.total
    fn         = obj.fn

    fn discussion, (err, data) =>
      if err
        throw err

      formData = JSON.parse JSON.stringify(config.formData)
      formData.body = @_fillPlaceholders formData.body, data
      formData.body = "#Script generated #{formData.body}"

      opts =
        url     : discussion.comments_href
        form    : formData
        headers :
          "X-Tender-Auth" : config.tender.apiKey
          "Accept"        : "application/vnd.tender-v1+json"
          "Content-Type"  : "application/json"

      request.post opts, (err, resp, body) ->
        if err
          throw err

        console.log "#{index} / #{total}: Handled #{discussion.html_href}"
        cb()

  _fetchComments: (href, cb) ->
    cmd = ["curl"]
    cmd.push "-H \"Accept: application/vnd.tender-v1+json\""
    cmd.push "-H \"X-Tender-Auth: #{config.tender.apiKey}\""
    cmd.push "-H \"Content-Type: application/json\""

    cmd = cmd.join " "
    cmd += " #{href}"

    childProcess.exec cmd, (err, stdout, stderr) =>
      parsed = null

      try
        parsed = JSON.parse stdout
      catch e
        return cb e

      cb err, parsed

  _fillPlaceholders: (body, dataToReplace) ->
    for key, val of dataToReplace
      regex = new RegExp "\{#{key}\}"
      body = body.replace regex, val

    return body


module.exports = DiscussionAnalyzer
