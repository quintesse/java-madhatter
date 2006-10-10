<%@ page
	language="java" 
	contentType="text/html; 
	charset=UTF-8" 
	pageEncoding="UTF-8" 
	import="javax.jcr.*,javax.naming.InitialContext,java.io.*"
%>

<%

boolean isNew = true;

String uuid = "";
String path = "";
String mimeType = "text/plain";
String encoding = "UTF-8";

String buttonName = (isNew) ? "Add" : "Update";

request.setAttribute("uuid", uuid);
request.setAttribute("path", path);
request.setAttribute("mimeType", mimeType);
request.setAttribute("encoding", encoding);
request.setAttribute("buttonName", buttonName);

%>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<title>Repo Dump</title>
</head>
<body>
	<form method="post">
		<table>
			<%
			if (!isNew) { 
			%>
			<tr>
				<td>UUID</td>
				<td>${uuid}</td>
			</tr>
			<% } %>
			<tr>
				<td>Path</td>
				<td><input type="text" name="path" value="${path}"></td>
			</tr>
			<tr>
				<td>Content type</td>
				<td><input type="text" name="mimetype" value="${mimeType}"></td>
			</tr>
			<tr>
				<td>Content encoding</td>
				<td><input type="text" name="encoding" value="${encoding}"></td>
			</tr>
			<tr>
				<td>Data</td>
				<td><textarea name="data" cols="80" rows="20"></textarea></td>
			</tr>
		</table>
		<input type="button" value="${buttonName}">
	</form>
	
</body>
</html>

<%!

%>
