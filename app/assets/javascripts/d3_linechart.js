

function plotWardLineChart(data,chartName){
	var padding = 100;
	var margin = {top: 20, right: 20, bottom: 30, left: 50},
      width = 750 - margin.left - margin.right,
      height = 300 - margin.top - margin.bottom;

    var x = d3.scale.linear()
    .domain([0, d3.max(data, function(d){return d.count})])
    .range([0,width]);

    var y = d3.scale.linear()
    .domain([0,d3.max(data, function(d){return d.count})])
    .range([height,0]);
    y.ticks(50);

    var x_axis = d3.svg.axis()
    .scale(x)
    .orient("bottom")
    .innerTickSize(-height)
    .outerTickSize(0)
    .tickPadding(10);

    var y_axis = d3.svg.axis()
    .scale(y)
    .orient("left")
    .innerTickSize(-width)
    .outerTickSize(0)
    .tickPadding(5);

    var line = d3.svg.line()
    .x(function(d) { return x(d.month);})
    .y(function(d) { return y(d.delta);});
    // .interpolate("basis");

    // data.forEach(function(d){
    // 	d.ward = parseDate(d.month);
    // 	d.delta = + d.delta
    // });
	var color = d3.scale.category10();
	color.domain(d3.keys(data[0]).filter(function(key) { return key !== "month"; }));
	var reports = color.domain().map(function(name){
		return {
			name: name,
			values: data.map(function(d){
				// console.log(d.month)
				// console.log(+d[name])
				return {month: d.month, delta: +d[name]};
			})
		};
	});



    var ward_chart = document.getElementById(chartName);
    

    x.domain(d3.extent(data, function(d){ return d.month;}));
    // y.domain(d3.extent(data, function(d){ return d.delta;}));
    y.domain([
    	d3.min(reports,function(d){return d3.min(d.values,function(v){return v.delta});}),
    	d3.max(reports,function(d){return d3.max(d.values,function(v){return v.delta});})
    	]);

    if(typeof(ward_chart)!= 'undefined' && ward_chart != null){
    	var svg = d3.select(chartName).transition();

    // Make the changes
    // console.log("report exist")
    	var report = d3.selectAll(".report")
    	.data(reports);

    	report.select("path.line")
    	.transition().duration(750)
    	.attr("d",function(d){return line(d.values);});

    	report.select("text.legend")
	      .datum(function(d) { return {name: d.name, value: d.values[d.values.length - 1]}; })
	      .transition().duration(750)
	      .attr("transform", function(d) { return "translate(" + x(d.value.month) + "," + y(d.value.delta) + ")"; })
	      .attr("x", 3)
	      .attr("dy", ".35em")
	      .text(function(d) { return d.name; });
    	
        // svg.select(".line")   // change the line
        //     .duration(750)
        //     .attr("d", line(reports));
        svg.select(".x.axis") // change the x axis
            .duration(750)
            .call(x_axis);
        svg.select(".y.axis") // change the y axis
            .duration(750)
            .call(y_axis);
        }else{  
            
            var leg_svg = d3.select("#d3-graph-legend").append("svg")
            .attr("height", height + margin.top + margin.bottom)
	        var svg = d3.select("#d3-graph").append("svg")
	          .attr("width", width + margin.left + margin.right + 100)
	          .attr("height", height + margin.top + margin.bottom)
	          .append("g")
	          .attr("id",chartName)
	          .attr("transform", "translate(" + margin.left + "," + margin.top + ")");
	        svg.append("g")
	            .attr("class", "x axis")
	            .attr("transform", "translate(0," + height + ")")
	            .call(x_axis);

	        svg.append("g")
	            .attr("class", "y axis")
	            .call(y_axis)
	            .append("text")
	            .attr("transform", "rotate(-90)")
	            .attr("y", 6)
	            .attr("dy", ".71em")
	            .style("text-anchor", "end")
	            .text("Delta");

           var report = svg.selectAll(".report")
		      .data(reports)
		    .enter().append("g")
		      .attr("class", "report");

		  report.append("path")
		      .attr("class", "line")
              .attr("data-legend",function(d){return d.name})
		      .attr("d", function(d) { return line(d.values); })
		      .style("stroke", function(d) { return color(d.name); });
          

    	  report.append("text")
    	      .datum(function(d) { return {name: d.name, value: d.values[d.values.length - 1]}; })
    	      .attr("transform", function(d) { return "translate(" + x(d.value.month) + "," + y(d.value.delta) + ")"; })
    	      .attr("x", 3)
    	      .attr("class","legend")
    	      .attr("dy", ".35em")
              .style("font-size","10px")
    	      .text(function(d) { return d.name; });

        

        legend = leg_svg.append("g")
                .attr("class","legend")
                .attr("transform","translate(50,30)")
                .style("font-size","12px")
                .call(d3.legend);
	      }
}

function plotTable(data){
    // var table = document.getElementById('graph-table');
    // if(table != null){
    //       table.deleteTHead();
    //       table.createTHead();
    //       console.log(table.rows.length)
    //       for(var i = 0; i < table.rows.length; i ++){
    //         table.deleteRow(i);
    //         console.log(i);
    //       }
    // }
    // var tableHeader = Object.keys(data[0]) 
    // // console.log(data)
    // // console.log(data[0])
    // $.each(tableHeader,function(key,value){
    //     $('#graph-table thead').append('<th>' + value + '</th>');
    // });
    // $("#graph-table").dynatable({
    //     table: {
    //         headRowSelector:'thead',
    //     },
    //     dataset:{
    //         records:data
    //     }
    // });
}

function clean_table(){
  var table = document.getElementById('graph-table');
  
}




