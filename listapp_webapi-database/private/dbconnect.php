<?php
  $servername = "localhost";
  $username = "listapp";
  $password = "2sAuaoDjIBQYzPp0";

  try {
    $conn = new PDO("mysql:host=$servername;dbname=listapp", $username, $password);
  } catch(PDOException $e) {
    echo "Connection failed: " . $e->getMessage();
    die();
  }
?>