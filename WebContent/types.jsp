<%@ page
	language="java" 
	contentType="text/html" 
	pageEncoding="UTF-8" 
	import="javax.jcr.*,
			javax.jcr.nodetype.*,
			org.apache.jackrabbit.name.*,
			org.apache.jackrabbit.core.nodetype.*,
			org.apache.jackrabbit.core.nodetype.compact.*,
			javax.naming.InitialContext,
			java.io.*,
			java.util.List"
%>

<%

String action = request.getParameter("action");
if (action == null || action.length() == 0) {
    action = "add";
}

boolean isNew = "add".equals(action);

String name = getValue(request.getParameter("name"), "");
String definition = getValue(request.getParameter("definition"), "");
String selectedType = getValue(request.getParameter("selected"), "");

InitialContext context = new InitialContext();
Repository repository = (Repository) context.lookup("java:comp/env/jcr/repository");
Session repSession = repository.login(new SimpleCredentials("username", "password".toCharArray()));
NodeTypeManager typemgr = repSession.getWorkspace().getNodeTypeManager();
NodeTypeRegistry ntreg = ((NodeTypeManagerImpl)typemgr).getNodeTypeRegistry();
SessionNamespaceResolver nsresolv = new SessionNamespaceResolver(repSession);

QName qname = null;
if (name.length() > 0) {
    qname = (name.startsWith("{")) ? QName.valueOf(name) : NameFormat.parse(name, nsresolv);
}

QName selectedQname = null;
if (selectedType.length() > 0) {
    selectedQname = (selectedType.startsWith("{")) ? QName.valueOf(selectedType) : NameFormat.parse(selectedType, nsresolv);
}
    
if (request.getParameter("submitted") != null) {
    if ("delete".equals(action)) {
        ntreg.unregisterNodeType(qname);
    }
    if ("add".equals(action) || "update".equals(action)) {
	    StringReader sreader = new StringReader(definition);
	    NamespaceMapping nsmap = new NamespaceMapping(nsresolv);
	    CompactNodeTypeDefReader reader = new CompactNodeTypeDefReader(sreader, name, nsmap);
	    List<NodeTypeDef> defs = reader.getNodeTypeDefs();
	    for (NodeTypeDef ntype : defs) {
		    if ("add".equals(action)) {
		        ntreg.registerNodeType(ntype);
		    }
		    if ("update".equals(action)) {
		        ntreg.reregisterNodeType(ntype);
		    }
	    }
    }
	response.sendRedirect("types.jsp?selected=" + name);
} else {
    if (qname != null) {
        NodeTypeDef ntype = ntreg.getNodeTypeDef(qname);
	    StringWriter swriter = new StringWriter();
	    CompactNodeTypeDefWriter writer = new CompactNodeTypeDefWriter(swriter, nsresolv);
	    writer.write(ntype);
	    definition = swriter.toString();
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
request.setAttribute("name", name);
request.setAttribute("definition", definition);
request.setAttribute("selectedType", selectedType);
request.setAttribute("buttonName", buttonName);

%>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<%@page import="org.apache.jackrabbit.util.name.NamespaceMapping"%>
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
			<td><textarea name="definition" cols="80" rows="10">${definition}</textarea></td>
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
	dump(out, ntreg, nsresolv, selectedQname);
%>
</table>

</body>
</html>

<%!
    private static void dump(JspWriter out, NodeTypeRegistry ntreg, SessionNamespaceResolver nsresolv, QName selectedQname) throws RepositoryException, IOException {
    	QName[] names = ntreg.getRegisteredNodeTypes();
    	for (QName name : names) {
    	    NodeTypeDef ntype = ntreg.getNodeTypeDef(name);

            // Output the node type info
    	    if (ntype.getName().equals(selectedQname)) {
	            out.print("<tr class=selected>");
            } else {
	            out.print("<tr>");
            }
            String nm = formatName(name, nsresolv);
            out.print("<td><span class=typename>" + nm + "</span></td>");
            out.print("<td><span class=nsuri>" + formatName(ntype.getPrimaryItemName(), nsresolv) + "</span></td>");
            
            // Write action links for node types
            out.print("<td>");
            out.print(" <a class=editlink href=\"types.jsp?action=update&name=" + nm + "\">edit</a>");
            out.print(" <a class=deletelink href=\"types.jsp?action=delete&name=" + nm + "\">delete</a>");
            out.print("</td>");
            out.print("</tr>");
    	}
    }

	private static String formatName(QName name, SessionNamespaceResolver nsresolv) {
        String nm = null;
        if (name != null) {
	        try {
	    	    nm = NameFormat.format(name, nsresolv);
	        } catch (NoPrefixDeclaredException ex) {
	            nm = name.toString();
	        }
        }
        return nm;
	}
	
	private String getValue(String value, String defaultValue) {
	    return (value != null) ? value : defaultValue;
	}
%>