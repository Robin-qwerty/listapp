<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);
require_once 'private/dbconnect.php';

try {
    if (!isset($_POST['username'], $_POST['password'])) {
        echo "ERROR3";
        exit;
    }

    $username = $_POST['username'];
    $password = $_POST['password'];

    $sql = "SELECT * FROM users WHERE username = :username AND archive = 0";
    $stmt = $conn->prepare($sql);
    $stmt->bindParam(':username', $username);
    $stmt->execute();
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($user) {
        if (password_verify($password, $user['password'])) {
            echo $user['userid'];
        } else {
            echo "ERROR2";
        }
    } else {
        echo "ERROR2";
    }
} catch (\Throwable $th) {
    echo "ERROR1";
}

?>
