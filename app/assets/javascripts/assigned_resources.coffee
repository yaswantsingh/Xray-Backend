jQuery ->
  if $('#assigned_resource_resource_id :selected').val() == ''
    $('#assigned_resource_resource_id').empty()
  $('#assigned_resource_staffing_requirement_input').change ->
    staffing_requirement_id = $('#assigned_resource_staffing_requirement_input :selected').val()
    if staffing_requirement_id != ''
      escaped_staffing_requirement_id = staffing_requirement_id.replace(/([ #;&,.+*~\':"!^$[\]()=>|\/@])/g, '\\$1')
      url = '/admin/api/skill_for_staffing?staffing_requirement_id=' + escaped_staffing_requirement_id
      $.ajax url,
        success: (data, status, xhr) ->
          $('#assigned_resource_skill_id').val(data.skill_id)
        error: (xhr, status, err) ->
          console.log(err)
      url = '/admin/api/designation_for_staffing?staffing_requirement_id=' + escaped_staffing_requirement_id
      $.ajax url,
        success: (data, status, xhr) ->
          $('#assigned_resource_designation_id').val(data.designation_id)
        error: (xhr, status, err) ->
          console.log(err)
      url = '/admin/api/hours_per_day_for_staffing?staffing_requirement_id=' + escaped_staffing_requirement_id
      $.ajax url,
        success: (data, status, xhr) ->
          $('#assigned_resource_hours_per_day').val(data.hours_per_day)
        error: (xhr, status, err) ->
          console.log(err)
      url = '/admin/api/start_date_for_staffing?staffing_requirement_id=' + escaped_staffing_requirement_id
      $.ajax url,
        success: (data, status, xhr) ->
          $('#assigned_resource_start_date').val(data.start_date)
        error: (xhr, status, err) ->
          console.log(err)
      url = '/admin/api/end_date_for_staffing?staffing_requirement_id=' + escaped_staffing_requirement_id
      $.ajax url,
        success: (data, status, xhr) ->
          $('#assigned_resource_end_date').val(data.end_date)
        error: (xhr, status, err) ->
          console.log(err)
      if staffing_requirement_id == ""
        $('#assigned_resource_resource_id').attr('disabled', true)
      else
        $('#assigned_resource_resource_id').attr('disabled', false)
        url = '/admin/api/resources_for_staffing?staffing_requirement_id=' + escaped_staffing_requirement_id
        $.ajax url,
          success: (data, status, xhr) ->
            $('#assigned_resource_resource_id').empty()
            $('#assigned_resource_resource_id').append('<option value=""></option>')
            result = JSON.parse data.resources
            i = 0
            while i < result.length
              $('#assigned_resource_resource_id').append('<option value="' + result[i].id + '">' + result[i].name + ' [Bill Rate: ' + result[i].bill_rate + ', Cost Rate: ' + result[i].cost_rate + ']' + '</option>')
              i++
            console.log result[0].name
          error: (xhr, status, err) ->
            console.log(err)
    else
      $('#assigned_resource_skill_id').val('')
      $('#assigned_resource_designation_id').val('')
      $('#assigned_resource_hours_per_day').val('')
      $('#assigned_resource_start_date').val('')
      $('#assigned_resource_end_date').val('')
      $('#assigned_resource_bill_rate').val('')
      $('#assigned_resource_cost_rate').val('')
  $('#assigned_resource_resource_id').change ->
    resource_id = $('#assigned_resource_resource_id :selected').val()
    escaped_resource_id = resource_id.replace(/([ #;&,.+*~\':"!^$[\]()=>|\/@])/g, '\\$1')
    url = '/admin/api/resource_details?resource_id=' + escaped_resource_id
    $.ajax url,
      success: (data, status, xhr) ->
        $('#assigned_resource_bill_rate').val(data.resource.bill_rate)
        $('#assigned_resource_cost_rate').val(data.resource.cost_rate)
      error: (xhr, status, err) ->
        console.log(err)