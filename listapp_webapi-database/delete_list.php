<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);
require_once 'private/dbconnect.php';

if (!isset($_POST['userId']) || !isset($_POST['listId'])) {
    echo json_encode(['error' => 'Missing parameters']);
    exit();
}

try {
    $userId = $_POST['userId'];
    $listId = $_POST['listId'];

    $query = "SELECT * FROM users WHERE userid = ? AND archive = 0";
    $statement = $conn->prepare($query);
    $statement->execute([$userId]);
    $user = $statement->fetch(PDO::FETCH_ASSOC);

    if ($user) {
        $updateQuery = "UPDATE lists SET archive = 1 WHERE id = ?";
        $updateStatement = $conn->prepare($updateQuery);
        $updateStatement->execute([$listId]);

        echo json_encode(['success' => true]);
    } else {
        echo json_encode(['error' => 'Invalid userId']);
        exit();
    }
} catch (PDOException $e) {
    echo json_encode(['error' => 'Failed to delete list: ' . $e->getMessage()]);
}
?>
