<?php
    if(isset($_POST['submit'])){
        $to = "alonso.fernandez@iesnervion.es";
        $from = $_POST['email'];
        $message = $_POST['message'];
        $subject = "Contact Form";
        $header = "From: " . $from;
        $result = mail($to, $subject, $message, $header);

        if($result) {
            echo '<p class="text-success">Sent!</p>';
        }else {
            echo '<p class="text-danger">Could not send :(</p>';
        }
    }
?>