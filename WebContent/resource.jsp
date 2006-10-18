<%@ page
	language="java" 
	contentType="text/html; charset=UTF-8" 
	pageEncoding="UTF-8" 
	import="javax.jcr.*,javax.jcr.nodetype.*,javax.naming.*,java.util.*,java.io.*"
%>

<%

String action = request.getParameter("action");
if (action == null || action.length() == 0) {
    action = "add";
}

boolean isNew = "add".equals(action);

String uuid = getValue(request.getParameter("uuid"), "");
String path = getValue(request.getParameter("path"), "");
String parentPath = getValue(request.getParameter("parentpath"), "");
String primaryNodeType = getValue(request.getParameter("primarynodetype"), "");
String name = getValue(request.getParameter("name"), "");

Session repSession = getSession();
if (request.getParameter("submitted") != null) {
	Node root = repSession.getRootNode();
	Node node;
	if (isNew) {
	    if (parentPath.length() > 0) {
	        path = parentPath;
	    }
	    if (path.length() > 0 && !path.endsWith("/")) {
	        path += "/";
	    }
	    path += name;
		node = root.addNode(path, primaryNodeType);
	} else {
        node = root.getNode(path);
	}
    String targetPath;
    if ("delete".equals(action)) {
        targetPath = node.getParent().getPath();
        node.remove();
		repSession.save();
    } else {
    	NodeType nodeType = getNodeType(primaryNodeType);
    	PropertyDefinition[] props = nodeType.getPropertyDefinitions();
    	for (PropertyDefinition prop : props) {
    	    String value = request.getParameter("prop_" + prop.getName());
    	    if (value != null) {
	    		node.getProperty(prop.getName()).setValue(value);
    	    }
    	}
		if (!isNew && !node.getName().equals(name)) {
		    String newPath = node.getParent().getPath();
		    if (!newPath.endsWith("/")) {
		        newPath += "/";
		    }
	        newPath += name;
		    repSession.move(node.getPath(), newPath);
		}
		repSession.save();
        targetPath = node.getPath();
    }
	response.sendRedirect("dump.jsp#" + targetPath);
} else {
    if (!isNew && (path.length() > 0 || uuid.length() > 0)) {
    	Node node = null;
        if (uuid != null && uuid.length() > 0) {
            node = repSession.getNodeByUUID(uuid);
        } else if (path != null && path.length() > 0) {
            Node root = repSession.getRootNode();
            node = root.getNode(path);
        }
        if (node != null) {
	        path = node.getPath().substring(1);
	        parentPath = node.getParent().getPath().substring(1);
	        primaryNodeType = node.getPrimaryNodeType().getName();
	        name = node.getName();
	    	NodeType nodeType = getNodeType(primaryNodeType);
	    	PropertyDefinition[] props = nodeType.getPropertyDefinitions();
	    	for (PropertyDefinition prop : props) {
	    	    if (node.hasProperty(prop.getName())) {
		    	    request.setAttribute("prop_" + prop.getName(), node.getProperty(prop.getName()).getValue().getString());
	    	    }
	    	}
        } else {
            isNew = true;
            action = "add";
        }
    }
}

String buttonName;
if ("add".equals(action)) {
    buttonName = "Add";
} else if ("update".equals(action)) {
    buttonName = "Update";
} else if ("delete".equals(action)) {
    buttonName = "Delete";
} else {
    buttonName = "???";
}

request.setAttribute("action", action);
request.setAttribute("path", path);
request.setAttribute("parentPath", parentPath);
request.setAttribute("primaryNodeType", primaryNodeType);
request.setAttribute("name", name);
request.setAttribute("buttonName", buttonName);

%>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=<%= response.getCharacterEncoding() %>">
<title>Repo Resource Manager</title>
</head>
<body>
	<form method="post" action="resource.jsp" accept-charset="UTF-8">
		<table>
			<tr>
				<td>Parent path</td>
				<td>${parentPath}/</td>
			</tr>
			<%
			if (isNew && primaryNodeType.length() == 0) { 
			%>
			<tr>
				<td>Primary node type</td>
				<td>
					<select name="primarynodetype">
						<%
						Node parentNode = repSession.getRootNode();
						if (parentPath.length() > 0) {
						    parentNode = parentNode.getNode(parentPath);
						}
						String[] defs = getAllowedNodeTypes(parentNode);
						for (String def : defs) {
						    out.println("<option>" + def + "</option>");
						}
						%>
					</select>
				</td>
			</tr>
			<% } else { %>
			<tr>
				<td>Primary node type</td>
				<td>${primaryNodeType}<input type="hidden" name="primarynodetype" value="${primaryNodeType}"></td>
			</tr>
			<% } %>
			<%
			if (!isNew || primaryNodeType.length() > 0) { 
			%>
			<tr>
				<td>Name</td>
				<td><input type="text" name="name" value="${name}"></td>
			</tr>
			
			<%
			writeProperties(out, request, primaryNodeType);
			%>
			
			<% } %>
		</table>
		<input type="hidden" name="path" value="${path}">
		<input type="hidden" name="parentpath" value="${parentPath}">
		<input type="hidden" name="action" value="${action}">
		<% if (!isNew || primaryNodeType.length() > 0) { %>
		<input type="submit" name="submitted" value="${buttonName}">
		<% } else { %>
		<input type="submit" name="continue" value="Continue">
		<% } %>
	</form>
	
</body>
</html>

<%!

private Session getSession() throws NamingException, RepositoryException {
	InitialContext context = new InitialContext();
	Repository repository = (Repository) context.lookup("java:comp/env/jcr/repository");
	Session session = repository.login(new SimpleCredentials("username", "password".toCharArray()));
	return session;
}

private String getValue(String value, String defaultValue) {
    return (value != null) ? value : defaultValue;
}

private String[] getAllowedNodeTypes(Node parentNode) throws NamingException, RepositoryException {
    HashSet<String> names = new HashSet<String>();
	NodeType type = parentNode.getPrimaryNodeType();
	NodeDefinition[] defs = type.getChildNodeDefinitions();
	for (NodeDefinition def : defs) {
	    if (def.getName().equals("*")) {
	        NodeTypeIterator iter = getSession().getWorkspace().getNodeTypeManager().getPrimaryNodeTypes();
	        while (iter.hasNext()) {
	            NodeType nodeType = iter.nextNodeType();
	            boolean isAssignable = true;
	            for (NodeType nt : def.getRequiredPrimaryTypes()) {
	                isAssignable = isAssignable && nodeType.isNodeType(nt.getName());
	            }
	            if (isAssignable) {
		            names.add(nodeType.getName());
	            }
	        }
	    } else {
		    names.add(def.getName() + "[" + def.getDefaultPrimaryType().getName() + "]");
	    }
	}
	String[] result = names.toArray(new String[names.size()]);
	Arrays.sort(result);
	return result;
}

private NodeType getNodeType(String typeName) throws NamingException, RepositoryException {
	NodeType nodeType = getSession().getWorkspace().getNodeTypeManager().getNodeType(typeName);
	return nodeType;
}

private void writeProperties(JspWriter out, HttpServletRequest request, String primaryNodeType) throws IOException, NamingException, RepositoryException {
	NodeType nodeType = getNodeType(primaryNodeType);
	PropertyDefinition[] props = nodeType.getPropertyDefinitions();
	for (PropertyDefinition prop : props) {
	    out.println("<tr>");
	    if (prop.isMandatory()) {
		    out.println("<td><b>" + prop.getName() + "</b></td>");
	    } else {
		    out.println("<td>" + prop.getName() + "</td>");
	    }
	    out.println("<td>");
	    if (prop.isProtected()) {
		    out.println(getValue((String)request.getAttribute("prop_" + prop.getName()), ""));
	    } else {
		    switch (prop.getRequiredType()) {
		    case PropertyType.BINARY:
			    out.println("<textarea cols=80 rows=20 name=\"prop_" + prop.getName() + "\">" + getValue((String)request.getAttribute("prop_" + prop.getName()), "") + "</textarea>");
		        break;
		    case PropertyType.BOOLEAN:
		        // TODO: NIY
			    out.println("Not implemented yet");
//			    out.println("<input type=\"text\" name=\"" + prop.getName() + "\" value=\"" + (String)request.getAttribute(prop.getName()) + "\">");
		        break;
		    case PropertyType.DATE:
		    case PropertyType.DOUBLE:
		    case PropertyType.LONG:
		    case PropertyType.NAME:
		    case PropertyType.PATH:
		    case PropertyType.REFERENCE:
		    case PropertyType.STRING:
			    out.println("<input type=\"text\" name=\"prop_" + prop.getName() + "\" value=\"" + getValue((String)request.getAttribute("prop_" + prop.getName()), "") + "\">");
		        break;
		    case PropertyType.UNDEFINED:
		        // TODO: NIY
			    out.println("Not implemented yet");
		        break;
		    }
	    }
	    out.println("</td>");
	    out.println("</tr>");
	}
}


%>

