<%@ page import="java.net.InetAddress" %>
<%@ page contentType="text/html;charset=UTF-8" %>
<!DOCTYPE html>
<html>
<head>
    <title>Login | Multi-Node Demo</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        body { font-family: Arial, Helvetica, sans-serif; margin: 20px; }
        
        .instance-info {
            background-color: #007bff;
            color: white;
            padding: 15px;
            border-radius: 8px;
            margin-bottom: 20px;
            text-align: center;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        }

        form { border: 3px solid #f1f1f1; max-width: 500px; margin: auto; }

        input[type=text], input[type=password] {
            width: 100%;
            padding: 12px 20px;
            margin: 8px 0;
            display: inline-block;
            border: 1px solid #ccc;
            box-sizing: border-box;
        }

        button {
            background-color: #04AA6D;
            color: white;
            padding: 14px 20px;
            margin: 8px 0;
            border: none;
            cursor: pointer;
            width: 100%;
            font-size: 16px;
        }

        button:hover { opacity: 0.8; }

        .cancelbtn {
            width: auto;
            padding: 10px 18px;
            background-color: #f44336;
        }

        /* NEW STYLE FOR CREATE ACCOUNT BUTTON */
        .reg-container {
            text-align: center;
            margin-top: 20px;
        }

        .regbtn {
            width: auto; 
            background-color: #2196F3;
            padding: 10px 24px;
        }

        .container { padding: 16px; }

        span.psw {
            float: right;
            padding-top: 16px;
        }

        @media screen and (max-width: 300px) {
            span.psw {
               display: block;
               float: none;
            }
            .cancelbtn, .regbtn {
               width: 100%;
            }
        }
    </style>
</head>
<body>

    <% 
        String hostname = "Unknown Server";
        try {
            hostname = InetAddress.getLocalHost().getHostName();
        } catch (Exception e) {
            hostname = "Error: " + e.getMessage();
        }
    %>

    <div class="instance-info">
        <strong>Infrastructure State:</strong> Healthy <br>
        <strong>Current Node:</strong> <code style="background: #0056b3; padding: 2px 5px; border-radius: 3px;"><%= hostname %></code>
    </div>

    <h2 style="text-align:center;">Login</h2>

    <form action="login" method="post">
        <div class="container">
            <label for="uname"><b>Username</b></label>
            <input type="text" placeholder="Enter Username" name="username" required>

            <label for="psw"><b>Password</b></label>
            <input type="password" placeholder="Enter Password" name="password" required>
                
            <button type="submit">Login</button>
            <label>
                <input type="checkbox" checked="checked" name="remember"> Remember me
            </label>
        </div>

        <div class="container" style="background-color:#f1f1f1">
            <button type="button" class="cancelbtn">Cancel</button>
            <span class="psw">Forgot <a href="#">password?</a></span>
        </div>
    </form>

    <% if (request.getParameter("error") != null) { %>
        <p style="color:red; text-align:center;">Invalid username or password</p>
    <% } %>
    
    <div class="reg-container">
        <a href="register.jsp">
            <button type="button" class="regbtn">Create Account</button>
        </a>
    </div>

</body>
</html>