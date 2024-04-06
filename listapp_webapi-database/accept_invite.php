<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);
require_once 'private/dbconnect.php';

session_start();

if (isset($_COOKIE['userId'])) {
    $_SESSION['userId'] = $_COOKIE['userId'];
}

if (isset($_SESSION['userId'])) {
    if (isset($_GET['code'])) {
        handleInviteAcceptance();
    } else {
        echo "Error: Invite code is missing. Check the url or ask the person that send you the url to send it again.";
    }
} else {
    handleLogin();
}

function handleLogin() {
    global $conn;
    
    $username = $_POST['username'];
    $password = $_POST['password'];
    
    $query = "SELECT * FROM users WHERE username = ?";
    $statement = $conn->prepare($query);
    $statement->execute([$username]);
    $user = $statement->fetch(PDO::FETCH_ASSOC);
    
    if ($user) {
        if (password_verify($password, $user['password'])) {
            $_SESSION['userId'] = $user['userid'];
                    
            setcookie('userId', $user['userid'], time() + (30 * 24 * 60 * 60), '/'); // Expires in 30 days
            
            handleInviteAcceptance();
        } else {
            echo "Invalid username or password. Please try again.";
        }
    } else {
        echo "Invalid username or password. Please try again.";
    }
}

function handleInviteAcceptance() {
    global $conn;
    
    $code = $_GET['code'];
    $userId = $_SESSION['userId'];
    
    try {
        $query = "SELECT * FROM invite WHERE code = ?";
        $statement = $conn->prepare($query);
        $statement->execute([$code]);
        $invite = $statement->fetch(PDO::FETCH_ASSOC);
    
        if ($invite) {
            $listId = $invite['groupid'];
            
            $query = "SELECT id FROM listgrouplink WHERE listid = ?";
            $statement = $conn->prepare($query);
            $statement->execute([$listId]);
            $listGroupLinkId = $statement->fetchColumn();
            
            if ($listGroupLinkId) {
                $query = "SELECT * FROM listgroup WHERE userid = ? AND listgrouplinkid = ?";
                $statement = $conn->prepare($query);
                $statement->execute([$userId, $listGroupLinkId]);
                $existingMembership = $statement->fetch(PDO::FETCH_ASSOC);
                
                if (!$existingMembership) {
                    $query = "INSERT INTO listgroup (userid, listgrouplinkid) VALUES (?, ?)";
                    $statement = $conn->prepare($query);
                    $statement->execute([$userId, $listGroupLinkId]);
                    
                    echo "User added to the group successfully. Go to the app to use the group list!";
                } else {
                    echo "User is already a member of this group. Go to the app to use the group list!";
                }
            } else {
                echo "Error: listgrouplink not found for listid. ask the person that send you the url to send a new one.";
            }
        } else {
            echo "Error: Invite not found or expired. Check the url or ask the person that send you the url to send it again.";
        }
    } catch (PDOException $e) {
        echo "Error: " . $e->getMessage();
    }
}


function displayLoginForm() {
    echo '
    <form method="post" action="">
        <label for="username">Username:</label><br>
        <input type="text" id="username" name="username" required><br>
        <label for="password">Password:</label><br>
        <input type="password" id="password" name="password" required><br><br>
        <input type="submit" name="login" value="Log In">
    </form>';
}
?>
