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

// Shows and hides contract end date depending on employee type selection
// This is temporary and should be removed when this UI is retired.
$(document).ready(function(){
  toggleContract();
  $('#employee_employee_type').change(toggleContract);

});

function toggleContract() {
  if ( $('#employee_employee_type').val() != 'Regular') {
    $("#employee_contract_end_date_1i").attr('required', true);
    $("#employee_contract_end_date_2i").attr('required', true);
    $("#employee_contract_end_date_3i").attr('required', true);
    $("#contract-date").show();
  } else {
    $("#employee_contract_end_date_1i").removeAttr('required');
    $("#employee_contract_end_date_2i").removeAttr('required');
    $("#employee_contract_end_date_3i").removeAttr('required');
    $("#contract-date").hide();
  }
}


// Generated by CoffeeScript 1.8.0
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
        title: 'Are you sure?',
        title_class: '',
        body: 'This action cannot be undone.',
        body_class: '',
        password: false,
        prompt: 'Type <strong>%s</strong> to continue:',
        footer_class: '',
        ok: 'Confirm',
        ok_class: 'button',
        cancel: 'Cancel',
        cancel_class: 'button secondary'
      };
      settings = $.extend({}, defaults, options);
      do_confirm = function($el) {
        var confirm_button, confirm_html, confirm_label, el_options, modal, option, password, _ref;
        el_options = $el.data('confirm');
        if ($el.attr('data-confirm') == null) {
          return true;
        }
        if ((typeof el_options === 'string') && (el_options.length > 0)) {
          return (((_ref = $.rails) != null ? _ref.confirm : void 0) || window.confirm).call(window, el_options);
        }
        option = function(name) {
          return el_options[name] || settings[name];
        };
        modal = $("<div data-reveal class='reveal'>\n  <h3 data-confirm-title class='" + (option('title_class')) + "'></h3>\n  <p data-confirm-body class='" + (option('body_class')) + "'></p>\n  <div data-confirm-footer class='" + (option('footer_class')) + "'>\n    <a data-confirm-cancel class='" + (option('cancel_class')) + "'></a>\n  </div>\n</div>");
        confirm_button = $el.is('a') ? $el.clone() : $('<a/>');
        confirm_button.removeAttr('data-confirm').attr('class', option('ok_class')).html(option('ok')).on('click', function(e) {
          if ($(this).prop('disabled')) {
            return false;
          }
          $el.trigger('confirm.reveal', e);
          if ($el.is('form, :input')) {
            console.log($el.closest('form'))
            return $el.closest('form').removeAttr('data-confirm').submit();
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
