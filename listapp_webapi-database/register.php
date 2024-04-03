<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);
require_once 'private/dbconnect.php';

try {
    // Check if both username and password are provided
    if (!isset($_POST['username'], $_POST['password'])) {
        echo "ERROR3";
        exit;
    }

    // Get username and password from request
    $username = $_POST['username'];
    $password = $_POST['password'];

    // Check if username is already taken
    $sql = "SELECT COUNT(*) AS count FROM users WHERE username = :username";
    $stmt = $conn->prepare($sql);
    $stmt->bindParam(':username', $username);
    $stmt->execute();
    $row = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($row['count'] > 0) {
        echo "ERROR2";
        exit;
    }

    // Hash the password securely
    $hashedPassword = password_hash($password, PASSWORD_DEFAULT);

    // Insert user into the database
    $sql = "INSERT INTO users (username, password) VALUES (:username, :password)";
    $stmt = $conn->prepare($sql);
    $stmt->bindParam(':username', $username);
    $stmt->bindParam(':password', $hashedPassword);

    if ($stmt->execute()) {
        // If registration is successful, return the user ID
        echo $conn->lastInsertId();
    } else {
        // If registration fails, return an error message
        echo "ERROR1";
    }
} catch (\Throwable $th) {
    echo "ERROR1";
}

?>
