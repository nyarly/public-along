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
//= require foundation
//= require_tree .

$(function(){ $(document).foundation(); });

// Shows and hides contract end date depending on employee type selection
// This is temporary and should be removed when this UI is retired.
$(document).ready(function(){
  toggleContract();
  $('#employee_employee_type').change(toggleContract);
  $('#application_access_level_select').change(updateAccessLevelNames);
  $('#add_al_id').click(addAccessLevelId);
  $('#add_al_from_sp').click(addToALList);
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

function updateAccessLevelNames() {
  $.ajax({
    type: 'get',
    url: '/update_al_opts',
    data: { application_id: $('#application_access_level_select').val()},
    success: function(data) {
      console.log("Dynamic select access level success");
    },
    error: function(error) {
      console.log("Dynamic select access level error");
    }
  })
}

function addAccessLevelId() {
  $.ajax({
    type: 'get',
    url: '/update_al_ids',
    data: { access_level_id: $('#access_level_name_select').val()},
    success: function(data) {
      console.log(data)
    }
  })
}

function addToALList() {
  console.log("update list of permissions")
}