<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Upload Posts</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-T3c6CoIi6uLrA9TneNEoa7RxnatzjcDSCmG1MXxSR1GAsXEV/Dwwykc2MPK8M2HN" crossorigin="anonymous">
    <link rel="stylesheet" href="../views/header.css">
</head>
<body>
    <?php include("../views/header.html")?>
    <div class="container">
        <h1>Add a new post:</h1>
        <form action="/restricted/upload.php" method="POST">
            <label class="form-label" for="post">Name of the post:</label>
            <br><input class="form-control" type="text" name="post"><br>
            <textarea name="message" rows="6" class="form-floating form-control" placeholder="Write here your markdown text!"></textarea><br>
            <input class="btn btn-dark btn-lg" name="submit" type="submit" value="Submit"/>
        </form>
    </div>
</body>
</html>