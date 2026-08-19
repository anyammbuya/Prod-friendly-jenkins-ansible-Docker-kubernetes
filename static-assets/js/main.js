// A simple toggle effect to show/hide the answers when clicked.
document.addEventListener("DOMContentLoaded", function() {
    console.log("Zeus Static JS Loaded and Connected Successfully via S3!");
    
    const questions = document.querySelectorAll('.faq-question');
    questions.forEach(q => {
        q.addEventListener('click', () => {
            const answer = q.nextElementSibling;
            if (answer.style.display === "block") {
                answer.style.display = "none";
            } else {
                answer.style.display = "block";
            }
        });
    });
});