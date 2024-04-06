<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);
require_once 'private/dbconnect.php';

// Check if the userId, listId, and inviteUserId are provided in the POST request
if (isset($_POST['userId'], $_POST['listId'], $_POST['inviteUserId'])) {
    // Retrieve userId, listId, and inviteUserId from POST request
    $userId = $_POST['userId'];
    $listId = $_POST['listId'];
    $inviteUserId = $_POST['inviteUserId'];

    // Check if the provided userId and inviteUserId exist in the database
    $query = "SELECT COUNT(*) AS count FROM users WHERE userid IN (?, ?) AND archive = 0";
    $statement = $conn->prepare($query);
    $statement->execute([$userId, $inviteUserId]);
    $row = $statement->fetch(PDO::FETCH_ASSOC);

    if ($row['count'] == 2) {
        try {
            // Begin a transaction
            $conn->beginTransaction();

            $query = "SELECT id FROM listgrouplink WHERE owner = ? AND listid = ?";
            $statement = $conn->prepare($query);
            $statement->execute([$userId, $listId]);
            $existingRow = $statement->fetch(PDO::FETCH_ASSOC);

            if (!$existingRow) {
                // If the row doesn't exist, insert a new record into listgrouplink table
                $query = "INSERT INTO listgrouplink (owner, listid) VALUES (?, ?)";
                $statement = $conn->prepare($query);
                $statement->execute([$userId, $listId]);

                // Get the last inserted ID from the listgrouplink table
                $listGrouplinkId = $conn->lastInsertId();
            } else {
                // If the row already exists, use its ID
                $listGrouplinkId = $existingRow['id'];
            }

            // Insert a new record into listgroup table
            $query = "INSERT INTO listgroup (userid, listgrouplinkid) VALUES (?, ?)";
            $statement = $conn->prepare($query);
            $statement->execute([$inviteUserId, $listGrouplinkId]);

            $conn->commit();

            // Return success message
            header('Content-Type: application/json');
            echo json_encode(['message' => 'List shared successfully']);
        } catch (PDOException $e) {
            // Rollback the transaction in case of an error
            $conn->rollBack();
            echo json_encode(['error' => 'Failed to share list: ' . $e->getMessage()]);
        }
    } else {
        // Invalid userId or inviteUserId
        echo json_encode(['error' => 'Invalid userId or inviteUserId']);
    }
} else {
    // Error handling if userId, listId, or inviteUserId is not provided
    echo json_encode(['error' => 'userId, listId, or inviteUserId is not provided']);
}
?>
