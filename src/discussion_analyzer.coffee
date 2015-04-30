request           = require "request"
async             = require "async"
childProcess      = require "child_process"
DiscussionFetcher = require "./discussion_fetcher"

class DiscussionAnalyzer
  constructor: ->
    @_filtered = []
    @_config = {}

  start: (config, cb) ->
    @_config = config

    if !@_config.tender.siteName || !@_config.tender.apiKey
      throw new Error "You need to supply Tender credentials!"

    opts =
      site   : @_config.tender.siteName
      apiKey : @_config.tender.apiKey
      state  : @_config.state

    fetcher = new DiscussionFetcher opts
    fetcher.fetch (err, discussions) =>
      if err
        throw err

      @_filterDiscussions discussions, (err) =>
        if err
          throw err

        @_fetchStatsForDiscussions @_filtered, cb

  _filterDiscussions: (discussions, cb) ->
    if discussions.length == 0
      return cb()

    q = async.queue @_filter.bind(this), 1
    q.drain = cb
    q.push discussions

  _filter: (discussion, cb) ->
    result = []

    if @_config.hoursAgo
      now      = +new Date
      hoursAgo = +new Date(now - (@_config.hoursAgo * 60 * 60 * 1000))

      thenTime = +new Date(discussion.created_at)
      if thenTime < hoursAgo
        return cb()


    # Do not consider items that already have a details comment
    @_fetchComments discussion.href, (err, result) =>
      if err
        return cb err

      hasComment = false

      for comment in result.comments
        match = comment.internal == @_config.formData.internal
        match = match && comment.author_email == @_config.formData.authorEmail
        match = match && /^\#Script generated/.test(comment.body)

        if match
          hasComment = true
          break

      if !hasComment
        @_filtered.push discussion

      cb()

  _fetchStatsForDiscussions: (discussions, cb) ->
    console.log "Need to update #{discussions.length} discussions"

    if discussions.length == 0
      return cb()

    q = async.queue @_fetchStats.bind(this), 1
    q.drain = cb

    index = 1
    for d in discussions
      obj =
        index      : index++
        total      : discussions.length
        discussion : d
      q.push obj

  _fetchStats: (obj, cb) ->
    discussion = obj.discussion
    index      = obj.index
    total      = obj.total

    @_config.fn discussion, (err, data) =>
      if err
        throw err

      if data == null
        msg = "#{index} / #{total}: Author of #{discussion.html_href}"
        msg += " is not a user"
        console.log msg
        return cb()

      formData = JSON.parse JSON.stringify(@_config.formData)
      formData.body = @_fillPlaceholders formData.body, data
      formData.body = "#Script generated #{formData.body}"

      opts =
        url     : discussion.comments_href
        form    : formData
        headers :
          "X-Tender-Auth" : @_config.tender.apiKey
          "Accept"        : "application/vnd.tender-v1+json"
          "Content-Type"  : "application/json"

      request.post opts, (err, resp, body) ->
        if err
          throw err

        msg = "#{index} / #{total}: Added comment for"
        msg += " #{discussion.html_href}"
        console.log msg
        cb()

  _fetchComments: (href, cb) ->
    cmd = ["curl"]
    cmd.push "-H \"Accept: application/vnd.tender-v1+json\""
    cmd.push "-H \"X-Tender-Auth: #{@_config.tender.apiKey}\""
    cmd.push "-H \"Content-Type: application/json\""

    cmd = cmd.join " "
    cmd += " #{href}"

    childProcess.exec cmd, (err, stdout, stderr) ->
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
