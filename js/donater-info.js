$(document).ready(function() {
    window.setInterval(function() {
      const currentValue = parseFloat($('#donated-interest').text());
      $('#donated-interest').text(`${currentValue * 1.000001}`);
    }, 3000);
});
