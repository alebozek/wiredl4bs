<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Contact - Wiredl4bs blog</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-T3c6CoIi6uLrA9TneNEoa7RxnatzjcDSCmG1MXxSR1GAsXEV/Dwwykc2MPK8M2HN" crossorigin="anonymous">
    <link rel="stylesheet" href="views/header.css">
</head>
<body>
    <?php include("views/header.html");?>
    <div class="container" style="min-height: 40em">
        <h1>Get in touch with me</h1>
        <form action="/form.php" method="POST">
            <label class="form-label" for="email">Email:</label><br>
            <input class="form-control" name="email" type="email"/><br>
            <label class="form-label" for="message">Message:</label><br>
            <textarea rows="6" class="form-floating form-control" name="message" placeholder="Write your message here!"></textarea>
            <br>
            <input name="submit" class="btn btn-dark btn-lg" type="submit" value="Send" />
        </form>
    </div>
    <?php include("views/footer.html");?>
</body>
</html>