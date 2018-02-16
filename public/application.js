$(function() {
  var secondsPassed = 0
  var refreshLimit = 60 * 2;

  $("#refresh-timer").text(refreshLimit);

  var interval = setInterval(function() {
    secondsPassed++;

    if (secondsPassed >= refreshLimit) {
      clearInterval(interval);
      window.location.reload();
    }

    $("#refresh-timer").text(refreshLimit - secondsPassed);
  }, 1000);
});
