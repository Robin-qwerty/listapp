<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);
require_once 'private/dbconnect.php';

if (isset($_POST['userid']) && isset($_POST['lists'])) {
    $userId = $_POST['userid'];
    $lists = json_decode($_POST['lists'], true)['lists'];

    try {
        $query = "SELECT COUNT(*) AS count FROM users WHERE userid = ? AND archive = 0";
        $statement = $conn->prepare($query);
        $statement->execute([$userId]);
        $row = $statement->fetch(PDO::FETCH_ASSOC);

        if ($row['count'] > 0) {
            foreach ($lists as $list) {
                if ($list['uploaded'] == 2) {
                    $insertQuery = "INSERT INTO lists (userid, name, archive) VALUES (?, ?, ?)";
                    $insertStatement = $conn->prepare($insertQuery);
                    $insertStatement->execute([$userId, $list['name'], $list['archive']]);
                } else {
                    $updateQuery = "UPDATE lists SET name = ?, archive = ? WHERE id = ?";
                    $updateStatement = $conn->prepare($updateQuery);
                    $updateStatement->execute([$list['name'], $list['archive'], $list['id']]);
                }
            }
            
            echo json_encode(['success' => true]);
        } else {
            echo json_encode(['error' => 'Invalid userId']);
        }
    } catch (PDOException $e) {
        echo json_encode(['error' => 'Failed to fetch lists: ' . $e->getMessage()]);
    }
} else {
    echo json_encode(['error' => 'userid or lists are not provided']);
}
?>
