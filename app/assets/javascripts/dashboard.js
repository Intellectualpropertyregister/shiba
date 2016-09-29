 $(document).ready(function(){

    $('#crime-type li').on('click',function(){
      $('#crime-type-text').val($(this).text());
    });
    $('#ward li').on('click',function(){
      $('#ward-text').val($(this).text());
    })
 });
 function crime_type_report(){
  var fromDate = document.getElementById('from-date').value;
  var toDate = document.getElementById('to-date').value;

  var crimeIndex = document.getElementById('crime-type-select');
  var crimeType = crimeIndex.options[crimeIndex.selectedIndex].value;

  var wardIndex = document.getElementById('ward-select');
  var wardNumber = wardIndex.options[wardIndex.selectedIndex].value;
  clean_chart("crime-type-chart");
  $.ajax({
        beforeSend: function(){
          spinner.spin(d3_graph);
        },
        complete: function(){
          spinner.stop();
        },
            type: "GET",
            contentType: "application/json",
            url: '/api/v1/reports/crime_type_report',
            dataType: 'json',
            data: {crime_type_id_eq : crimeType,
                 occurred_at_gteq : fromDate,
                 occurred_at_lteq : toDate,
                 ward_eq : wardNumber},
            success: function (data) {
              console.log('success')
              // console.log(data)
              plotWardLineChart(data,"crime-type-chart");
              plotTable(data);
            },
            error: function (data) {
              console.log('Error')
            }
    })
}
 

function wards_daytime_report(){
  var fromDate = document.getElementById('from-date').value;
  var toDate = document.getElementById('to-date').value;

  var crimeIndex = document.getElementById('crime-type-select');
  var crimeType = crimeIndex.options[crimeIndex.selectedIndex].value;

  var wardIndex = document.getElementById('ward-select');
  var wardNumber = wardIndex.options[wardIndex.selectedIndex].value;
  clean_chart("daytime-chart");
  $.ajax({
        beforeSend: function(){
          spinner.spin(d3_graph);
        },
        complete: function(){
          spinner.stop();
        },
            type: "GET",
            contentType: "application/json",
            url: '/api/v1/reports/wards_report',
            dataType: 'json',
            data: {crime_type_id_eq : crimeType,
                 occurred_at_gteq : fromDate,
                 occurred_at_lteq : toDate,
                 ward_eq : wardNumber},
            success: function (data) {
              console.log('success')
              // console.log(data)
              plotWardLineChart(data,"daytime-chart");
              plotTable(data);
            },
            error: function (data) {
              console.log('Error')
            }
    })
}

function narcotics_report(){
  var fromDate = document.getElementById('from-date').value;
  var toDate = document.getElementById('to-date').value;
  var wardIndex = document.getElementById('ward-select');
  var wardNumber = wardIndex.options[wardIndex.selectedIndex].value;
  clean_chart("narcotics-chart");
  $.ajax({
      beforeSend: function(){
          spinner.spin(d3_graph);
        },
        complete: function(){
          spinner.stop();
        },
            type: "GET",
            contentType: "application/json",
            url: '/api/v1/reports/narcotics_report',
            dataType: 'json',
            data: {occurred_at_gteq : fromDate,
                 occurred_at_lteq : toDate,
                 ward_eq : wardNumber},
            success: function (data) {
              console.log('success')
              // console.log(data)
              plotWardLineChart(data,"narcotics-chart");
              plotTable(data);
            },
            error: function (data) {
              console.log('Error')
            }
    })
}

function clean_chart(chart_name){
  
  var previous_svg = document.getElementById(chart_name);
  // console.log(previous_svg);
  if(previous_svg == null ){
   d3.selectAll("svg").remove();
  }
}






