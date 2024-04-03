<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);
require_once 'private/dbconnect.php';

// Check if the required parameters are provided
if (!isset($_POST['userId']) || !isset($_POST['listName'])) {
    echo json_encode(['error' => 'Missing parameters']);
    exit();
}

try {
    // Assign parameters to variables
    $userId = $_POST['userId'];
    $listName = $_POST['listName'];

    // Prepare and execute SQL statement to check if user exists
    $query = "SELECT * FROM users WHERE userid = ? AND archive = 0";
    $statement = $conn->prepare($query);
    $statement->execute([$userId]);
    $user = $statement->fetch(PDO::FETCH_ASSOC);

    // Check if user exists
    if ($user) {
        // Prepare and execute SQL statement to insert new list
        $query = "INSERT INTO lists (userid, name) VALUES (?, ?)";
        $statement = $conn->prepare($query);
        $statement->execute([$userId, $listName]);
        $lists = $statement->fetch(PDO::FETCH_ASSOC);
    }
    else {
        echo json_encode(['error' => 'Invalid userId']);
        exit();
    }
} catch (\Throwable $th) {
    // Error handling if userId or listId is not provided
    echo json_encode(['error' => 'userId or listId is not provided']);
}

?>
