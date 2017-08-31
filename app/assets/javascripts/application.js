// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
//= require jquery-ui
//= require foundation
//= require autocomplete-rails
//= require_tree .

$(function(){ $(document).foundation(); });

$(document).ready(function(){
  showSelectedEmployee();
  selectLinkedEmployee();
  clearLinkedEmployee();
  toggleReuseEmail();
});

function toggleReuseEmail() {
  $('#link-account-switch').on('click', function(event) {
    $('.switch-input').click(function(event) {
      event.stopPropagation();
    });

    link_email = $('#manager_entry_link_email').val();
    if (link_email == "off") {
      $('#manager_entry_link_email').val("on");
      $('#find-email').show();
      $('#manager_entry_linked_account_id').val("");
    } else {
      $('#manager_entry_link_email').val("off");
      $('#find-email').hide();
      $('#linked-employee').hide();
    }
  });
}

function showSelectedEmployee() {
  // binds to select from autocomplete
  $('#manager_entry_linked_account_id').bind('railsAutocomplete.select', function(event, data){
    if (data.item.value == "no existing match") {
      $('#manager_entry_linked_account_id').val("");
      return false;
    } else {
      date_options = { year: 'numeric', month: 'long', day: 'numeric' };
      hire_date = new Date(data.item.hire_date);
      $('#linked-emp-fn').text(data.item.first_name);
      $('#linked-emp-fn').text(data.item.first_name);
      $('#linked-emp-ln').text(data.item.last_name);
      $('#linked-emp-email').text(data.item.value);
      $('#linked-emp-hd').text(hire_date.toLocaleDateString("en-US", date_options));
      $('#show-selected-employee').show();
    }
  });
}

function selectLinkedEmployee() {
  $('#select_linked_account').click(function(event) {
    event.preventDefault();
    email = $('#manager_entry_linked_account_id').val();
    acct_name = $('#linked-emp-fn').text() + " " + $('#linked-emp-ln').text();
    $('#show-selected-employee').hide();
    $('#linked-employee').show();
    $('#reuse-email').text(email);
    $('#linked-name').text(acct_name);
  });
}

function clearLinkedEmployee() {
  $('.clear_linked_account').click(function(event) {
    event.preventDefault();
    $('#show-selected-employee').hide();
    $('#manager_entry_linked_account_id').val("");
    $('#linked-employee').hide();
  });
}

// Custom form confirmation using Foundation
(function() {
  var $;

  $ = this.jQuery;

  $.fn.extend({
    confirmWithReveal: function(options) {
      var defaults, do_confirm, handler, settings;
      if (options == null) {
        options = {};
      }
      defaults = {
        modal_class: 'medium',
        title: 'Please confirm that you have made the correct selections.',
        body: 'This action cannot be undone.',
        ok: 'Confirm',
        ok_class: 'button',
        cancel: 'Cancel',
        cancel_class: 'button secondary'
      };
      settings = $.extend({}, defaults, options);
      do_confirm = function($el) {
        var confirm_button, confirm_html, confirm_label, el_options, modal, option, _ref;
        el_options = $el.data('confirm');
        if ($el.attr('data-confirm') == null) {
          return true;
        }
        if ((typeof el_options === 'string') && (el_options.length > 0)) {
          return (((_ref = $.rails) != null ? _ref.confirm : void 0) || window.confirm).call(window, el_options);
        }
        option = function(name) {
           // if link email is off, use default confirmation msg instead of custom
          link_email = $('#manager_entry_link_email').val();
          if (link_email == "off") {
            return settings[name]
          } else {
            return el_options[name] || settings[name];
          }
        };
        modal = $("<div data-reveal class='reveal'>\n  <h3 data-confirm-title class='" + (option('title_class')) + "'></h3>\n  <p data-confirm-body class='" + (option('body_class')) + "'></p>\n  <div data-confirm-footer class='" + (option('footer_class')) + "'>\n    <a data-confirm-cancel class='" + (option('cancel_class')) + "'></a>\n  </div>\n</div>");
        confirm_button = $el.is('a') ? $el.clone() : $('<a/>');
        confirm_button.removeAttr('data-confirm').attr('class', option('ok_class')).html(option('ok')).on('click', function(e) {
          if ($(this).prop('disabled')) {
            return false;
          }
          $el.trigger('confirm.reveal', e);
          if ($el.is('form, :input')) {
            // validate form with js
            if ($el.closest('form')[0].checkValidity()) {
              return $el.closest('form').removeAttr('data-confirm').submit();
            } else {
              // if form is invalid, remove confirm, click submit to trigger html5 validation, restore confirm
              modal.foundation('close');
              $('#submit_confirm').removeAttr('data-confirm');
              $el.closest('form').find(':submit').click();
              $('#submit_confirm').attr('data-confirm', '');
              return false;
            }
          }
        });
        modal.find('[data-confirm-title]').html(option('title'));
        modal.find('[data-confirm-body]').html(option('body'));
        modal.find('[data-confirm-cancel]').html(option('cancel')).on('click', function(e) {
          modal.foundation('close');
          return $el.trigger('cancel.reveal', e);
        });
        modal.find('[data-confirm-footer]').append(confirm_button);
        modal.appendTo($('body')).foundation().foundation('open').on('closed.fndtn.reveal', function(e) {
          return modal.remove();
        });
        return false;
      };
      if ($.rails) {
        $.rails.allowAction = function(link) {
          return do_confirm($(link));
        };
        return $(this);
      } else {
        handler = function(e) {
          if (!(do_confirm($(this)))) {
            e.preventDefault();
            return e.stopImmediatePropagation();
          }
        };
        return this.each(function() {
          var $el;
          $el = $(this);
          $el.on('click', 'a[data-confirm], :input[data-confirm]', handler);
          $el.on('submit', 'form[data-confirm]', handler);
          return $el;
        });
      }
    }
  });
}).call(this);

$(document).confirmWithReveal()
