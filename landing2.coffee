#                      _          _ _   _
#                     | |        (_) | | |
#   ___  ___ _ __   __| |_      ___| |_| |__  _   _ ___
#  / __|/ _ \ '_ \ / _` \ \ /\ / / | __| '_ \| | | / __|
#  \__ \  __/ | | | (_| |\ V  V /| | |_| | | | |_| \__ \
#  |___/\___|_| |_|\__,_| \_/\_/ |_|\__|_| |_|\__,_|___/
#
#
# DOM-based Routing
# Based on http://goo.gl/EUTi53 by Paul Irish
#
# Only fires on body classes that match.

try_carousel = () ->
  $('.carousel').carousel( interval: 0 )

  $('.send-it').on('click', () ->
    $('.carousel').carousel(1)
  )

  $('.run-it').on('click', () ->
    $('.carousel').carousel(2)
  )

  $('.tweak-it').on('click', () ->
    $('.carousel').carousel(1)
  )

maximize_container = (container, offset = 0, center) ->
  maximized_height = $(window).height() - offset
  container.outerHeight(maximized_height)

maximize_all = (container) ->
  container.each (index, element) ->
    maximize_container($(element), navbar_height(), true)

navbar_height = () ->
  return $('.navbar').height() - 1

scroll_to = (element, duration=100) ->
  $('html, body').animate({
    scrollTop: element.offset().top - navbar_height()
  }, duration)

get_host = () ->
  if window.location.host.indexOf('sendwithus.com') > -1
    host = 'https://app.sendwithus.com'
  else
    # strip xip.io if its being used
    host = window.location.origin.replace('.xip.io','')
    host = host.replace('https', 'http') # strip https
    host = host.replace(':8888', ':8000') # relace port

  return host

api_call = (json) ->
  # host = get_host()

  # $.ajax(
  #   url: "#{host}/ajax/send_email/"
  #   contentType: "text/plain"
  #   data: json
  #   error: (jqXHR, textStatus, errorThrown) ->
  #     console.log textStatus
  #   success: () ->
  #     # Successful
  #     return
  # )

  data = $.parseJSON(json)
  $('#sentEmailModal .modal-email').text(data.recipient.address)
  $('#sentEmailModal').modal('show')

# This is a hack to get cors to work
# for more info, see greg or brandon
$.ajaxSetup(
  type: "POST"
  headers:
    'X-Requested-With': 'XMLHttpRequest'
)


# DOM-based routing

SWU_LANDING =
  common:
    init: () ->
      # Scroll events for nav
      $(window).scroll(() ->
        # Scroll offset
        scroll_top = $(window).scrollTop()
        if scroll_top > 20
          $('.navbar').addClass('float')
        else
          $('.navbar').removeClass('float')
      )

      # Continue button
      $('.continue').on('click', () ->
        if $(@).attr('data-id')
          element = "##{$(@).attr('data-id')}"
        else
          element = 'continue'
        scroll_to($(element), 500)
      )

      # Contact form
      # Post ajax-forms with AJAX
      $('.ajax-form').on('submit', (e) ->
        e.preventDefault()
        $form = $(@)
        $form.trigger('ajax-form-submit')

        host = get_host()

        $.ajax(
          type: 'POST'
          dataType: 'json'
          url: "#{host}/ajax/#{$form.attr('action')}"
          data: $form.serialize()
          success: (data, textStatus, jqXHR) ->
            $form.trigger('ajax-form-response', [data])
          error: (jqXHR, textStatus, errorThrown) ->
            console.log(textStatus, errorThrown)
            alert('An unexpected error occurred, try again later.')
        )

        return false
      )

      # Setup youtube colorboxes
      $('a.youtube').colorbox(
        iframe: true
        innerWidth: 1280
        innerHeight: 720
      )

      $('.contact-request-form')
        .on('ajax-form-submit', (event) ->
          $(event.target).find('[type=submit]').prop('disabled', true)
          $(event.target).find('.form-group').removeClass('has-error')

        )
        .on('ajax-form-response', (event, response) ->
          $form = $(event.target)

          if response.success
            $form.find('.form-contents').css('display', 'none')
            $form.find('.collapse.thanks').collapse('show')

            $form.fadeTo(200, 0.9)
            $form.find('input, textarea').prop('disabled', true)
            $form.find('.form-row').slideUp()
          else
            $form.find('.form-group').addClass('has-error')

          $form.find('[type=submit]').prop('disabled', false)
        )

      $('.email-tips-form')
        .on('ajax-form-submit', (event) ->
          $(event.target).find('[type=submit]').prop('disabled', true)
          $(event.target).find('.form-group').removeClass('has-error')
        )
        .on('ajax-form-response', (event, response) ->
          $form = $(event.target)

          if response.success
            $form.find('.form-contents').css('display', 'none')
            $form.find('.collapse.thanks').collapse('show')

            $form.fadeTo(200, 0.9)
            $form.find('input, textarea').prop('disabled', true)
            $form.find('.form-row').slideUp()
          else
            $form.find('.form-group').addClass('has-error')

          $form.find('[type=submit]').prop('disabled', false)
        )

  home:
    init: () ->
      return

  developers:
    init: () ->
      $popover = $('.popover')
      $runEmailAddress = $('#run-email-address')

      $('.run-it').on('click', () ->
        # Make sure that people have changed the email before trying to run
        if $runEmailAddress.text() is $runEmailAddress.attr('data-default')
          # Shake
          $popover.removeClass('shake')
          # Next tick
          setTimeout(() ->
            $popover.addClass('shake')
          , 0)

          return

        # Verify if email is correct
        if not $runEmailAddress.text().match(/.+@.+\..+/)
          $('#valid-email-modal').popover('show')

          # Shake
          $popover.removeClass('shake')
          # Next tick
          setTimeout(() ->
            $popover.addClass('shake')
          , 0)

          return

        data =
          email_id: "swu_email_emWvGb6pH"
          recipient:
            address: $runEmailAddress.text()
          email_data:
            first_name: $('#run-first-name').text()
            url: $('#run-url').text()
            items: JSON.parse($('#run-items').text())

        json = JSON.stringify data
        api_call(json)
      )

      # Show email tooltip
      $runEmailAddress.popover('show')
      $runEmailAddress.on('click', () ->
        $('#valid-email-modal').popover('hide')
      )

      $('[contenteditable="true"]')
        .on('click', () ->
          # If a popover exists for this element, hide it.
          $runEmailAddress.popover('hide')
          $(this).attr('data-cache', $(this).text())
          $(this).text('')
        )
        .on('blur', () ->
          element = $(this)
          if element.text() is '' or null
            if element.attr('data-cache')
              element.text(element.attr('data-cache'))
            else
              element.text(element.attr('data-default'))

            if element.text() is element.attr('data-default')
              $(this).popover('show')
        )
        .on('keypress', (e) ->
          if e.charCode is 13
            e.preventDefault()
            $(this).blur()
        )

  guide:
    init: () ->
      content_top = $('.guide-content').offset().top - $('header').height()

      $('body').scrollspy(
        target: '.bs-docs-sidebar',
        offset: $('header').height()
      )

      left_nav = $('.bs-docs-sidebar')

      $(window).bind("scroll", () ->
        offset = $(@).scrollTop()

        if offset >= content_top
          left_nav.addClass('affix')
        else
          left_nav.removeClass('affix')
      )

  pricing:
    init: () ->
      largestHeight = 0

      $('.pricing-plan').each((i, el) ->
        h = $(el).height()
        largestHeight = h > largestHeight ? h : largestHeight
      )

      $('.pricing-plan.outside').height(largestHeight)
      $('.pricing-plan.middle').height(largestHeight + 20)

      $('.do-contact-sales').on('click', (event) ->
        event.preventDefault()
        $('#contact_sales_modal').modal('show')
        setTimeout(() ->
          $('#contact_sales_modal').find('input').first().focus()
        , 500)
      )

      $('.contact-notify-form').on('ajax-form-submit', (event) ->
        event.preventDefault()
        $('#contact-notify-modal').modal('show')
      )

      $('.contact-sales-form')
        .on('ajax-form-submit', (event) ->
          $(event.target).find('[type=submit]').prop('disabled', true)
          $(event.target).find('.form-group').removeClass('has-error')
        )
        .on('ajax-form-response', (event, response) ->
          if response.success
            $(event.target).find('.collapse').collapse('show')
          else
            $(event.target).find('.form-group').addClass('has-error')

          $(event.target).find('[type=submit]').prop('disabled', false)
        )

  segmentation:
    init: () ->
      $('.segmentation-form .dropdown-menu a').on('click', (e) ->
        e.preventDefault()
        $btn = $(@)
        $parentBtn = $btn.parents().find('> button')
        $parentBtn.html("#{$btn.text()}&nbsp;<span class='caret'></span>")
      )

  gallery:
    init: () ->
      $(document).on(
        mouseenter: () ->
          $(@).find('.gallery-hover').fadeIn(100)
        mouseleave: () ->
          $(@).find('.gallery-hover').fadeOut(250)
      , '.gallery-thumb')

      $('a.gallery-preview').colorbox({photo:true})

      $contributors = $('#contributors')

      $contributors.css('display', 'none')

      token = $contributors.attr('data-gh')
      $contributors.removeAttr('data-gh')

      gh = new Github(
        token: token
        auth: 'oauth'
      )

      repo = gh.getRepo('sendwithus', 'templates')

      # Get the contributors to the templates repo
      repo.contributors (err, contributors) ->
        if not err?
          html = ""

          # sort by total contributions, high -> low
          contributors.sort (a, b) ->
            return b.total - a.total

          for contributor in contributors
            html += """
            <div style='display:inline-block'>
              <a href='#{contributor.author.html_url}'
                target='_blank'
                title='Follow @#{contributor.author.login} on Github!'>
                <img class='img-circle'
                  src='#{contributor.author.avatar_url}'
                  style='width:45px;height:45px'>
              </a>
            </div>
            """

          $contributors.html(html).fadeIn()

  generator:
    init: () ->
      default_num_columns = 3
      default_gutter_width = 10

      $dropdown_num_columns   = $('.dropdown-num-columns')
      $input_gutter_width     = $('.input-gutter-width')
      $form_generate_layout   = $('.form-generate-layout')
      $input_email_width      = $('.input-email-width')
      $pre_layout_preview     = $('.pre-layout-preview')
      $div_layout_preview     = $('.div-layout-preview')
      $num_columns_containers = $('.num-columns')

      num_columns = default_num_columns

      jokes = [
        "If you hold a Unix shell to your ear do you hear the C?"
        "Why do computer scientists need glasses? To C#"
        "It's pretty void in here..."
        "Why did the Integer drown? Because it couldn't Float."
        "Why did the programmer quit her job? Because she coundn't get Arrays"
        "What's the best thing thing about UDP jokes? I don't care if you get them"
        "Knock Knock Who's there? (long pause) Java."
        "An SQL query enters a bar, approaches two tables
          and asks: \"May I join you?\"."
        "A web designer walks into a bar, but immediately leaves
          in disgust upon noticing the tables layout"
        "A programmer heads out to the store.
          His wife says \"while you're out, get some milk.\" ... He never came home."
        "An SEO expert walks into a bar, pub, liquor store,
          brewery, alcohol, beer, whiskey, vodka"
        "What's the best part about TCP jokes? I get to keep
          telling them until you get them."
        "In order to understand recursion you must first understand recursion."
        "A testing engineer walks into a bar. Runs into a bar. Crawls into a bar.
          Dances into a bar. Tiptoes into a bar. Rams into a bar. Jumps into a bar.
          Slides into a bar. Stumbles into a bar. Looks at a bar."
      ]

      current_joke = Math.floor(Math.random() * jokes.length)

      $dropdown_num_columns.on('click', 'li', (e) ->
        e.preventDefault()
        $item = $(e.target)
        num_columns = $item.attr('data-num-columns')
        $num_columns_containers.text("#{num_columns} #{get_qualifier(num_columns)}")
      )

      $form_generate_layout.on('submit', (e) ->
        e.preventDefault()
        generate_html()
      )

      get_joke = () ->
        return jokes[current_joke++ % jokes.length]

      get_qualifier = (num_columns) ->
        qualitier = 'Column'

        if num_columns > 1
          qualitier += 's'

        return qualitier

      create_pre_container = () ->
        return $('<pre class="pre-layout-preview prettyprint" skin="sunburst"></pre>')

      generate_html = () ->
        gutter_width = parseInt($input_gutter_width.val(), 10)
        email_width = parseInt($input_email_width.val(), 10)

        gutter_consideration = Math.floor((gutter_width * (num_columns - 1)) / num_columns)
        col_width = Math.floor(email_width / num_columns) - gutter_consideration

        column_html = ''
        comment = "#{num_columns} column layout with #{gutter_width}px spacing"
        html = "<!-- #{comment} -->\n"
        html += "<table width=\"#{email_width}\" cellpadding=\"0\" cellspacing=\"0\" align=\"center\">\n  <tr>\n"

        column_discriptor = 'Column'
        if num_columns > 4
          column_discriptor = 'Col'

        for i in [1..num_columns]
          joke = get_joke()
          html += "    <td width=\"#{col_width}\">\n"
          html += "      <h2>#{column_discriptor} #{i}</h2>\n"
          html += "      <p>#{joke}</p>\n"
          html += "    </td>\n"

          if i < num_columns
            html += "    <td width=\"#{gutter_width}\">&nbsp;</td>\n"

        html += "  </tr>\n</table>"

        # We need to create new <pre> so prettify picks
        # up on it.
        $new_pre = create_pre_container()

        $new_pre.text(html)
        $div_layout_preview.html(html)

        $pre_layout_preview.empty().append($new_pre)

        # re-run prettify
        PR.prettyPrint()

      generate_html()

  sendgrid:
    init: () ->
     # Ambassador tracking
      qs = ((a) ->
        if a is ''
          return {}
        b = {}
        i = 0
        while i < a.length
          p = a[i].split('=', 2)
          if p.length is 1
            b[p[0]] = ''
          else
            b[p[0]] = decodeURIComponent(p[1].replace(/\+/g, ' '))
          ++i
        b
      )(window.location.search.substr(1).split('&'))

      # set the tracking src
      $('<img>').attr('src', "#{get_host()}/ajax/mbasy?#{$.param(qs)}")

  emailstack:
    init: () ->
      controller = new ScrollMagic.Controller

      #First Image
      containerScene = new ScrollMagic.Scene(
        triggerElement: '#container'
        duration: $(window).width()
        offset: -65
        triggerHook: 0
        reverse: true).setPin('#demopic', pushFollowers: false)

      #Second Image
      containerScene2 = new ScrollMagic.Scene(
        triggerElement: '#container2'
        duration: $(window).width()
        offset: -65
        triggerHook: 0
        reverse: true).setPin('#demopic2', pushFollowers: false)

      #Third Image
      containerScene3 = new ScrollMagic.Scene(
        triggerElement: '#container3'
        duration: $(window).width()
        offset: -65
        triggerHook: 0
        reverse: true).setPin('#demopic3', pushFollowers: false)

      #Fourth Image
      containerScene4 = new ScrollMagic.Scene(
        triggerElement: '#container4'
        duration: $(window).width()
        offset: -65
        triggerHook: 0
        reverse: true).setPin('#demopic4', pushFollowers: false)

      #Fifth Image
      containerScene5 = new ScrollMagic.Scene(
        triggerElement: '#container5'
        duration: $(window).width()
        offset: -65
        triggerHook: 0
        reverse: true).setPin('#demopic5', pushFollowers: false)

      #Sixth Image
      containerScene6 = new ScrollMagic.Scene(
        triggerElement: '#container6'
        duration: 1100
        offset: -65
        triggerHook: 0
        reverse: true).setPin('#demopic6', pushFollowers: false)

      #Seventh Image
      containerScene7 = new ScrollMagic.Scene(
        triggerElement: '#container7'
        duration: 600
        offset: -65
        triggerHook: 0
        reverse: true).setPin('#demopic7', pushFollowers: false)

      controller.addScene [
        containerScene
        containerScene2
        containerScene3
        containerScene4
        containerScene5
        containerScene6
        containerScene7
      ]

      tabletController = new ScrollMagic.Controller

      #First Image
      tabletScene = new ScrollMagic.Scene(
        triggerElement: '#tablet'
        duration: 300
        offset: 10
        triggerHook: 0.5
        reverse: true).setPin('#tabletpic', pushFollowers: false)

      tabletScene1 = new ScrollMagic.Scene(
        triggerElement: '#tablet1'
        duration: 500
        offset: -115
        triggerHook: 0
        reverse: true).setPin('#tabletpic1', pushFollowers: false)      

      tabletScene2 = new ScrollMagic.Scene(
        triggerElement: '#tablet2'
        duration: 650
        offset: -165
        triggerHook: 0
        reverse: true).setPin('#tabletpic2', pushFollowers: false)

      tabletScene3 = new ScrollMagic.Scene(
        triggerElement: '#tablet3'
        duration: 500
        offset: -135
        triggerHook: 0
        reverse: true).setPin('#tabletpic3', pushFollowers: false)

      tabletScene4 = new ScrollMagic.Scene(
        triggerElement: '#tablet4'
        duration: 600
        offset: -100
        triggerHook: 0
        reverse: true).setPin('#tabletpic4', pushFollowers: false)

      tabletScene5 = new ScrollMagic.Scene(
        triggerElement: '#tablet5'
        duration: 1000
        offset: -200
        triggerHook: 0
        reverse: true).setPin('#tabletpic5', pushFollowers: false)

      tabletScene6 = new ScrollMagic.Scene(
        triggerElement: '#tablet6'
        duration: 560
        offset: -155
        triggerHook: 0
        reverse: true).setPin('#tabletpic6', pushFollowers: false)

      tabletController.addScene [
        tabletScene
        tabletScene1
        tabletScene2
        tabletScene3
        tabletScene4
        tabletScene5
        tabletScene6
      ]

# Hack to make the promo page work
SWU_LANDING.promo = SWU_LANDING.signup

UTIL =
  fire: (func, funcname, args) ->
    namespace = SWU_LANDING
    funcname = if funcname is undefined then 'init' else funcname

    if func isnt '' and namespace[func] and typeof namespace[func][funcname] is 'function'
      namespace[func][funcname](args)

  loadEvents: () ->
    UTIL.fire('common')

    $.each(document.body.className.split(/\s+/), (i, class_name) ->
      body_tag = class_name.replace('body-', '').replace(/-/g, '_')
      UTIL.fire(body_tag)
    )

$(document).ready(UTIL.loadEvents)