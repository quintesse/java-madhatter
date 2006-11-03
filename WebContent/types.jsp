<%@ page
	language="java" 
	contentType="text/html" 
	pageEncoding="UTF-8" 
	import="javax.jcr.*,javax.jcr.nodetype.*,org.apache.jackrabbit.core.nodetype.compact.*,org.apache.jackrabbit.core.nodetype.*,javax.naming.InitialContext,java.io.*,java.util.*"
%>

<%

String action = request.getParameter("action");
if (action == null || action.length() == 0) {
    action = "add";
}

boolean isNew = "add".equals(action);

String name = getValue(request.getParameter("name"), "");
String definition = getValue(request.getParameter("definition"), "");
String selectedType = request.getParameter("selected");

InitialContext context = new InitialContext();
Repository repository = (Repository) context.lookup("java:comp/env/jcr/repository");
Session repSession = repository.login(new SimpleCredentials("username", "password".toCharArray()));
NodeTypeManager typemgr = repSession.getWorkspace().getNodeTypeManager();

if (request.getParameter("submitted") != null) {
    if ("delete".equals(action) || "update".equals(action)) {
//        nsreg.unregisterNamespace(prefix);
    }
    if ("add".equals(action) || "update".equals(action)) {
//        nsreg.registerNamespace(prefix, uri);
    }
	response.sendRedirect("types.jsp?selected=" + name);
} else {
    NodeType ntype = typemgr.getNodeType(name);
    CompactNodeTypeDefWriter writer;
    writer.write(ntype);
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
request.setAttribute("name", name);
request.setAttribute("definition", definition);
request.setAttribute("selectedType", selectedType);
request.setAttribute("buttonName", buttonName);

%>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=<%= response.getCharacterEncoding() %>">
	<title>Types</title>
	<style>
		.typestable {
			border-width : 1;
			border-style : solid;
		}
		.selected {
			background-color : red;
		}
		.typename {
			font-weight : bold;
		}
		.nsuri {
			color : green;
		}
		TR.selected .typename {
			font-weight : bold;
			color : white;
		}
		TR.selected .nsuri {
			color : yellow;
		}
	</style>
</head>
<body>

<form method="post" action="types.jsp">
	<table>
		<tr>
			<td>Name</td>
			<td>
				<% if (isNew) { %>
				<input type="text" name="name" value="${name}">
				<% } else { %>
				${name}
				<input type="hidden" name="name" value="${name}">
				<% } %>
			</td>
		</tr>
		<tr>
			<td>Definition</td>
			<td><textarea name="definition" cols="80" rows="20">${definition}</textarea></td>
		</tr>
	</table>
	<input type="hidden" name="action" value="${action}">
	<input type="submit" name="submitted" value="${buttonName}">
</form>

<p>

<table class=typestable>
<thead>
	<tr>
		<th>Name</th>
		<th>???</th>
		<th>Action</th>
	</tr>
</thead>
<%
	dump(out, typemgr, selectedType);
%>
</table>

</body>
</html>

<%!
    private static void dump(JspWriter out, NodeTypeManager typemgr, String selectedType) throws RepositoryException, IOException {
	    // Get the NodeTypeManager from the Workspace.
	    // Note that it must be cast from the generic JCR NodeTypeManager to the
	    // Jackrabbit-specific implementation.
	    NodeTypeManagerImpl ntmgr =(NodeTypeManagerImpl)typemgr;

	    // Acquire the NodeTypeRegistry
	    NodeTypeRegistry ntreg = ntmgr.getNodeTypeRegistry();
	    
    	NodeTypeIterator iter = typemgr.getAllNodeTypes();
    	while (iter.hasNext()) {
    	    NodeType ntype = (NodeType) iter.next();

            // Output the node type info
    	    if (ntype.getName().equals(selectedType)) {
	            out.print("<tr class=selected>");
            } else {
	            out.print("<tr>");
            }
            out.print("<td><span class=typename>" + ntype.getName() + "</span></td>");
            out.print("<td><span class=nsuri>" + ntype.getPrimaryItemName() + "</span></td>");
            
            // Write action links for node types
            out.print("<td>");
            out.print(" <a class=editlink href=\"types.jsp?action=update&name=" + ntype.getName() + "\">edit</a>");
            out.print(" <a class=deletelink href=\"types.jsp?action=delete&name=" + ntype.getName() + "\">delete</a>");
            out.print("</td>");
            out.print("</tr>");
    	}
    }

	private String getValue(String value, String defaultValue) {
	    return (value != null) ? value : defaultValue;
	}
%>
