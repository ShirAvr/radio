var averageChart, rangeChart, chart, currentType, createAverageChart, before, after;
const minHeight = 300

var generateDataPoints = function(data, type) {
  return data.map(function(value, index) {
    return { x: 10*(index+1), y: value[type], label: value.route };
  });
}

var filteredData = function(data, text) {
  return data.filter(function(value) {
    return value.route.indexOf(text) != -1;
  });
}

var filterRoutes = function() {
  if(before == undefined || after == undefined) return;

  var text = document.getElementById("filter").value;

  var filteredBefore = filteredData(before, text);
  var filteredAfter = filteredData(after, text);

  if(!text) {
    chart.options.data[0].dataPoints = generateDataPoints(before, currentType);
    chart.options.data[1].dataPoints = generateDataPoints(after, currentType);
    chart.options.height = Math.max(before.length*50, minHeight);
  } else {
    chart.options.data[0].dataPoints = generateDataPoints(filteredBefore, currentType)
    chart.options.data[1].dataPoints = generateDataPoints(filteredAfter, currentType)
    chart.options.height = Math.max(filteredBefore.length*50, minHeight);
  }

  chart.render();
}

var changeCurrentChart = function() {
  var type = document.getElementById("currentChart").value

  switch(type) {
    case "average":
      chart = createAverageChart();
      break;
    case "range":
      chart = createRangeChart();
      break;
    case "errors":
      chart = createErrorsChart();
      break;
  }

  currentType = type;
  chart.render();

  document.getElementById("filter").value = ""
  filterRoutes()
}

var createAverageChart = function() {
  return new CanvasJS.Chart("chartContainer",
    {
      title: {
        text: "Average Chart",
        fontSize: 50            
      },
      
      animationEnabled: true,
      height: Math.max(before.length*50, minHeight),

      axisY: {
        title: "Time(ms)",
        labelFontSize: 15,
        titleFontSize: 20
      },
      
      axisX :{
        interval: 10,
        labelFontSize: 15
      },

      legend: {
        verticalAlign: "bottom",
        fontSize: 20
      },
      
      data: [
        {        
          type: "bar",  
          showInLegend: true, 
          bevelEnabled: true,
          legendText: "before",
          dataPoints: generateDataPoints(before, "average")
        },
        {        
          type: "bar",  
          showInLegend: true,
          bevelEnabled: true,
          legendText: "after",
          dataPoints: generateDataPoints(after, "average")
        }
      ]
    }
  );
}

var createRangeChart = function() {
  return new CanvasJS.Chart("chartContainer",
    {
      title:{
        text: "Range Chart",
        fontSize: 50
      },

      animationEnabled: true,
      height: Math.max(before.length*50, minHeight),

      axisY: {
        title: "Time(ms)",
        includeZero: false,
        labelFontSize: 15,
        titleFontSize: 20
      }, 
      
      axisX: {
        interval: 10,
        labelFontSize: 15
      },

      legend: {
        verticalAlign: "bottom",
        fontSize: 20
      },

      data: [
        {
          type: "rangeBar",
          showInLegend: true,
          bevelEnabled: true,
          legendText: "before",
          dataPoints: generateDataPoints(before, "range")
        },
        {
          type: "rangeBar",
          showInLegend: true,
          bevelEnabled: true,
          legendText: "after",
          dataPoints: generateDataPoints(after, "range")
        }
      ]
    }
  );
}

var createErrorsChart = function() {
  return new CanvasJS.Chart("chartContainer",
    {
      title: {
        text: "Errors Chart",
        fontSize: 50            
      },
      
      animationEnabled: true,
      height: Math.max(before.length*50, minHeight),

      axisY: {
        title: "Number of Errors",
        interval: 1,
        labelFontSize: 15,
        titleFontSize: 20
      },
      
      axisX :{
        interval: 10,
        labelFontSize: 15
      },

      legend: {
        verticalAlign: "bottom",
        fontSize: 20
      },
      
      data: [
        {        
          type: "bar",  
          showInLegend: true, 
          bevelEnabled: true,
          legendText: "before",
          dataPoints: generateDataPoints(before, "errors")
        },
        {        
          type: "bar",  
          showInLegend: true,
          bevelEnabled: true,
          legendText: "after",
          dataPoints: generateDataPoints(after, "errors")
        }
      ]
    }
  );
}

window.onload = function () {
  $.get("http://localhost:4000/getData", function(data) {
    before = data.before;
    after = data.after;
    currentType = "average";
    chart = createAverageChart();
    chart.render();
  });
}