<?php
    function listPosts() {
        $files = scandir('posts');
        for($i = 2; $i < sizeof($files); $i++){
            $pathInfo = pathinfo($files[$i], PATHINFO_FILENAME);
            echo "<h3><a class='link-dark' href='posts/$files[$i]'>$pathInfo</a></h3>";
        }
    }
?>