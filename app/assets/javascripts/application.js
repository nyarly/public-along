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
