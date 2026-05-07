<?php
    require("functions.php");
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-T3c6CoIi6uLrA9TneNEoa7RxnatzjcDSCmG1MXxSR1GAsXEV/Dwwykc2MPK8M2HN" crossorigin="anonymous">
    <link rel="stylesheet" href="views/header.css">
    <title>Wiredl4bs blog</title>
</head>
<body>
    <?php include 'views/header.html';?>
    <div class="container">
        <h1>Wiredl4bs blog</h1>
        <p>
            This is a blog about Cybersecurity, coding and tech in general. In here I will post my findings when tinkering with technology and code.
            I'm very curious so, I guarantee you I'll bring interesting stuff to this site. My content can be in either spanish or english depending on the day really.
        </p>
        <br>
        <h2>Posts:</h2>
        <div class="posts" style="min-height: 30em;">
            <?php listPosts();?>
        </div>
    </div><br>
    <?php include 'views/footer.html'?>
</body>
</html>