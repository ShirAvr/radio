var i = success = error = 0;

var interval = setInterval(function(){
  percentage = 100 - $.active
  $('.progress-bar-success').css('width', success +'%').attr('aria-valuenow', success);
  $('.progress-bar-danger').css('width', error +'%').attr('aria-valuenow', error);
  $('.percentage').text(percentage + '%');
  if(percentage == 100) clearInterval(interval);
}, 100);

while(i < 100) {
  var method;

  if (0 <= i && i < 20) 
    method = "GET";
  else if (20 <= i && i < 40)
    method = "POST";
  else if (40 <= i && i < 60)
    method = "PUT";
  else if (60 <= i && i < 80) 
    method = "DELETE";
  else if (80 <= i && i < 100) 
    method = "PATCH";

  $.ajax({
    type: method,
    url: "http://localhost:3000/random" + i,
    success: function(msg) {
      success++
      console.log("SUCCESS: " + JSON.stringify(msg));
    },
    error: function(msg) {
      error++
      console.log("ERROR: " + JSON.stringify(msg));
    }
  })

  i++;
}