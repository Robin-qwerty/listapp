<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    exit();
}

require_once 'private/dbconnect.php';

if (!isset($_POST['userId']) || !isset($_POST['listName'])) {
    echo json_encode(['error' => 'Missing parameters']);
    exit();
}

try {
    $userId = $_POST['userId'];
    $listName = $_POST['listName'];

    $query = "SELECT * FROM users WHERE userid = ? AND archive = 0";
    $statement = $conn->prepare($query);
    $statement->execute([$userId]);
    $user = $statement->fetch(PDO::FETCH_ASSOC);

    if ($user) {
        $query = "INSERT INTO lists (userid, name) VALUES (?, ?)";
        $statement = $conn->prepare($query);
        $statement->execute([$userId, $listName]);
        $lists = $statement->fetch(PDO::FETCH_ASSOC);

        echo json_encode(['message' => 'List added successfully']);
    }
    else {
        echo json_encode(['error' => 'Invalid userId']);
        exit();
    }
} catch (\Throwable $th) {
    echo json_encode(['error' => 'userId or listId is not provided']);
}

?>
