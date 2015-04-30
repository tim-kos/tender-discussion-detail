childProcess = require "child_process"
async        = require "async"
_            = require "underscore"

class DiscussionFetcher
  constructor: (opts) ->
    @apiKey = opts.apiKey || process.env.TENDER_SITENAME || null
    @site   = opts.site   || process.env.TENDER_APIKEY || null
    @state  = opts.state  || "pending"
    @since  = opts.since  || null

    @url = @_buildUrl()

    @numPages    = 0
    @err         = null
    @discussions = []

  _buildUrl: ->
    url = "http://api.tenderapp.com/#{@site}/discussions/#{@state}"
    return url

  _validates: ->
    if !@apiKey
      return new Error "You need to set an API key."

    if !@site
      return new Error "You need to set a Tender site name."

  fetch: (cb) ->
    console.log "Fetching discussions to consider"

    err = @_validates()
    if err
      return cb err

    @_fetchPage 1, =>
      if @pageCount < 2
        return @_end cb

      q = async.queue @_fetchPage.bind(this), 5
      q.drain = =>
        return @_end cb

      for num in [2..@pageCount]
        q.push num

  _end: (cb) ->
    @discussions = _.unique @discussions
    console.log "Found #{@discussions.length} discussions to consider"
    cb @err, @discussions

  _fetchPage: (page, cb) ->
    if @err
      return cb()

    cmd = ["curl"]
    cmd.push "-H \"Accept: application/vnd.tender-v1+json\""
    cmd.push "-H \"X-Tender-Auth: #{@apiKey}\""
    cmd.push "-H \"Content-Type: application/json\""

    cmd = cmd.join " "
    cmd += " #{@url}?page=#{page}"

    childProcess.exec cmd, (err, stdout, stderr) =>
      @_offset += @_perPage

      if err
        @err = err
        return cb err

      parsed = null

      try
        parsed = JSON.parse stdout
      catch e
        @err = e
        return cb()

      for d in parsed.discussions
        entry =
          title         : d.title
          html_href     : d.html_href
          href          : d.href
          comments_href : d.comments_href.replace /\{\?page\}/, ""
          author_email  : d.author_email
          created_at    : d.created_at

        @discussions.push entry

      if page == 1
        @pageCount = Math.ceil parsed.total / parsed.per_page

      cb()

module.exports = DiscussionFetcher
