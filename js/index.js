$(document).ready(function() {

    $('.carousel').carousel({
      fullWidth: true,
      indicators: true
    });

    const carouselElement = document.querySelector('#gamification-stats .carousel');
    const carouselInstance = M.Carousel.getInstance(carouselElement);

    window.setInterval(function() {
      carouselInstance.next();
    }, 5000);

});
