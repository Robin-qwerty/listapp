<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    exit();
}

require_once 'private/dbconnect.php';

if (isset($_POST['userid']) && isset($_POST['groupid'])) {
    $groupid = $_POST['groupid'];
    $userId = $_POST['userid'];

    try {
        $query = "SELECT COUNT(*) AS count FROM users WHERE userid = ? AND archive = 0";
        $statement = $conn->prepare($query);
        $statement->execute([$userId]);
        $row = $statement->fetch(PDO::FETCH_ASSOC);

        if ($row['count'] > 0) {

        } else {
            echo json_encode(['error' => 'Invalid userId']);
        }
    } catch (PDOException $e) {
        echo json_encode(['error' => 'Failed to upload lists and items: ' . $e->getMessage()]);
    }
} else {
    echo json_encode(['error' => 'userid, lists, or items are not provided']);
}
?>
