<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    exit();
}

require_once 'private/dbconnect.php';

if (isset($_POST['userId'], $_POST['listId'], $_POST['inviteUserId'])) {
    $userId = $_POST['userId'];
    $listId = $_POST['listId'];
    $inviteUserId = $_POST['inviteUserId'];

    $query = "SELECT COUNT(*) AS count FROM users WHERE userid IN (?, ?) AND archive = 0";
    $statement = $conn->prepare($query);
    $statement->execute([$userId, $inviteUserId]);
    $row = $statement->fetch(PDO::FETCH_ASSOC);

    if ($row['count'] == 2) {
        try {
            $conn->beginTransaction();

            $query = "SELECT id FROM listgrouplink WHERE owner = ? AND listid = ?";
            $statement = $conn->prepare($query);
            $statement->execute([$userId, $listId]);
            $existingRow = $statement->fetch(PDO::FETCH_ASSOC);

            if (!$existingRow) {
                $query = "INSERT INTO listgrouplink (owner, listid) VALUES (?, ?)";
                $statement = $conn->prepare($query);
                $statement->execute([$userId, $listId]);

                $listGrouplinkId = $conn->lastInsertId();
            } else {
                $listGrouplinkId = $existingRow['id'];
            }

            $query = "INSERT INTO listgroup (userid, listgrouplinkid) VALUES (?, ?)";
            $statement = $conn->prepare($query);
            $statement->execute([$inviteUserId, $listGrouplinkId]);

            $conn->commit();

            header('Content-Type: application/json');
            echo json_encode(['message' => 'List shared successfully']);
        } catch (PDOException $e) {
            $conn->rollBack();
            echo json_encode(['error' => 'Failed to share list: ' . $e->getMessage()]);
        }
    } else {
        echo json_encode(['error' => 'Invalid userId or inviteUserId']);
    }
} else {
    echo json_encode(['error' => 'userId, listId, or inviteUserId is not provided']);
}
?>
