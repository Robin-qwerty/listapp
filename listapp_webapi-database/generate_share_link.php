<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    exit();
}

require_once 'private/dbconnect.php';

if (isset($_POST['userId']) && isset($_POST['listId'])) {
    $userId = $_POST['userId'];
    $listId = $_POST['listId'];

    try {
        $query = "SELECT COUNT(*) AS count FROM users WHERE userid = ? AND archive = 0";
        $statement = $conn->prepare($query);
        $statement->execute([$userId]);
        $user = $statement->fetch(PDO::FETCH_ASSOC);

        $query = "SELECT COUNT(*) AS count FROM lists WHERE id = ? AND archive = 0";
        $statement = $conn->prepare($query);
        $statement->execute([$listId]);
        $list = $statement->fetch(PDO::FETCH_ASSOC);

        if ($user['count'] > 0 && $list['count'] > 0) {
            $query = "SELECT id FROM listgrouplink WHERE owner = ? AND listid = ?";
            $statement = $conn->prepare($query);
            $statement->execute([$userId, $listId]);
            $listGrouplinkId = $statement->fetchColumn();

            if (!$listGrouplinkId) {
                $query = "INSERT INTO listgrouplink (owner, listid) VALUES (?, ?)";
                $statement = $conn->prepare($query);
                $statement->execute([$userId, $listId]);
            }

            $query = "SELECT code FROM invite WHERE listid = ?";
            $statement = $conn->prepare($query);
            $statement->execute([$listId]);
            $existingCode = $statement->fetchColumn();

            if (!$existingCode) {
                $code = generateUniqueCode();

                $query = "INSERT INTO invite (listid, code) VALUES (?, ?)";
                $statement = $conn->prepare($query);
                $statement->execute([$listId, $code]);
            } else {
                $code = $existingCode;
            }

            echo json_encode(['success' => true, 'code' => "the group code: $code", 'link' => "https://robin.humilis.net/flutter/listapp/accept_invite.php?code=$code"]);
        } else {
            echo "ERROR3";
        }
    } catch (PDOException $e) {
        echo "ERROR1";
    }
} else {
    echo "ERROR2";
}

function generateUniqueCode() {
    $characters = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
    $code = '';
    for ($i = 0; $i < 8; $i++) {
        $code .= $characters[rand(0, strlen($characters) - 1)];
    }
    return $code;
}
?>
