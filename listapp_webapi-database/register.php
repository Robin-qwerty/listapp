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

    $sql = "SELECT COUNT(*) AS count FROM users WHERE username = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bindParam(1, $username);
    $stmt->execute();
    $row = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($row['count'] > 0) {
        echo "ERROR2";
        exit;
    }

    $hashedPassword = password_hash($password, PASSWORD_DEFAULT);

    $sql = "INSERT INTO `users` (`username`, `password`) VALUES (?, ?)";
    $stmt = $conn->prepare($sql);
    $stmt->bindParam(1, $username);
    $stmt->bindParam(2, $hashedPassword);

    if ($stmt->execute()) {
        echo $conn->lastInsertId();
    } else {
        echo "ERROR1";
    }
} catch (\Throwable $th) {
    echo "ERROR1";
}

?>
