<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    exit();
}

require_once 'private/dbconnect.php';

if (isset($_POST['userId'])) {
    $userId = $_POST['userId'];

    try {
        $query = "SELECT COUNT(*) AS count FROM users WHERE userid = ? AND archive = 0";
        $statement = $conn->prepare($query);
        $statement->execute([$userId]);
        $row = $statement->fetch(PDO::FETCH_ASSOC);

        if ($row['count'] > 0) {
            $query = "SELECT l.*, COUNT(g.id) AS shared_with_count
                FROM lists l
                LEFT JOIN listgrouplink lg ON l.id = lg.listid
                LEFT JOIN listgroup g ON lg.id = g.listgrouplinkid
                WHERE g.userid = ?
                AND l.archive = 0
                GROUP BY l.id";
            $statement = $conn->prepare($query);
            $statement->execute([$userId]);
            $lists = $statement->fetchAll(PDO::FETCH_ASSOC);

            header('Content-Type: application/json');
            echo json_encode($lists);
        } else {
            echo json_encode(['error' => 'Invalid userId, userid: '.$_POST['userId']]);
        }
    } catch (PDOException $e) {
        echo json_encode(['error' => 'Failed to fetch lists: ' . $e->getMessage()]);
    }
} else {
    echo json_encode(['error' => 'userid is not provided']);
}
?>
