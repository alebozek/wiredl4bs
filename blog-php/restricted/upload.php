<?php
    ini_set('display_errors', '1');
    include '../vendor/autoload.php';

    function requireToVariable($file) {
        ob_start();
        require($file);
        return ob_get_clean();
    }
    
    if(isset($_POST['message']) && isset($_POST['post'])) {
        $namePost = $_POST['post'];
        $message = $_POST['message'];
        $pageContent = Parsedown::instance()->text($message);
        $header = requireToVariable('../views/header.html');
        $footer = requireToVariable('../views/footer.html');
        $page = '<!DOCTYPE html>
                <html lang="en">
                <head>
                    <meta charset="UTF-8">
                    <meta name="viewport" content="width=device-width, initial-scale=1.0">
                    <title>' . $namePost . ' - Wiredl4bs blog</title>
                    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-T3c6CoIi6uLrA9TneNEoa7RxnatzjcDSCmG1MXxSR1GAsXEV/Dwwykc2MPK8M2HN" crossorigin="anonymous">
                    <link rel="stylesheet" href="../views/header.css">
                </head>
                <body>
                ' . $header . '
                    <div class="container">
                    ' . $pageContent . '
                    </div>
                ' . $footer . '
                </body>
                </html>'; 
        echo $page;
        
        $file = fopen('../posts/' . $namePost . '.php', "w") or die("<p class='text-danger'>Could not create file</p>");
        fwrite($file, $page);
    }
?>

