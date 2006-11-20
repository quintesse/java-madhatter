<%@ page
	language="java" 
	contentType="text/html; charset=UTF-8" 
	pageEncoding="UTF-8" 
	import="javax.jcr.*,javax.jcr.nodetype.*,javax.naming.*,java.util.*,java.util.regex.*,java.io.*"
%>

<!-- 
 * [madhatter] Codejive CMS package
 * 
 * Copyright (C) 2006 Tako Schotanus
 * 
 * This library is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2, or (at your option)
 * any later version.
 * 
 * This library is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
 * more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this library; see the file COPYING.  If not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
 * 02110-1301 USA.
 * 
 * Linking this library statically or dynamically with other modules is
 * making a combined work based on this library.  Thus, the terms and
 * conditions of the GNU General Public License cover the whole
 * combination.
 *
 * As a special exception, the copyright holders of this library give you
 * permission to link this library with independent modules to produce an
 * executable, regardless of the license terms of these independent
 * modules, and to copy and distribute the resulting executable under
 * terms of your choice, provided that you also meet, for each linked
 * independent module, the terms and conditions of the license of that
 * module.  An independent module is a module which is not derived from
 * or based on this library.  If you modify this library, you may extend
 * this exception to your version of the library, but you are not
 * obligated to do so.  If you do not wish to do so, delete this
 * exception statement from your version.
 * 
-->

<%

String action = request.getParameter("action");
if (action == null || action.length() == 0) {
    action = "add";
}

boolean isNew = "add".equals(action);

String uuid = getValue(request.getParameter("uuid"), "");
String path = getValue(request.getParameter("path"), "");
String parentPath = getValue(request.getParameter("parentpath"), "");

Session repSession = getSession();
if (request.getParameter("submitted") != null) {
	String name = getValue(request.getParameter("prop_name"), "");
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
		String primaryNodeType = getValue(request.getParameter("prop_primarynodetype"), "");
	    node = createNode(root, path, primaryNodeType, "prop_", request);
	} else {
        node = root.getNode(path);
        setNodeProperties(node, "prop_", request);
	}
    String targetPath;
    if ("delete".equals(action)) {
        targetPath = node.getParent().getPath();
        node.remove();
		repSession.save();
    } else {
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
	return; // Is this the proper way??
} // else {
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
	    	NodeType nodeType = node.getPrimaryNodeType();
    	    request.setAttribute("prop_name", node.getName());
    	    request.setAttribute("prop_primarynodetype", nodeType.getName());
	    	PropertyDefinition[] props = nodeType.getPropertyDefinitions();
	    	for (PropertyDefinition prop : props) {
	    	    if (node.hasProperty(prop.getName())) {
	    	        if (prop.isMultiple()) {
	    	            Value[] values = node.getProperty(prop.getName()).getValues();
			    	    request.setAttribute("prop_count_" + prop.getName(), Integer.toString(values.length));
			    	    for (int i = 0; i < values.length; i++) {
			    	        Value value = values[i];
				    	    request.setAttribute("prop_#" + i + "_" + prop.getName(), value2Str(value));
			    	    }
	    	        } else {
	    	            Value value = node.getProperty(prop.getName()).getValue();
			    	    request.setAttribute("prop_" + prop.getName(), value2Str(value));
	    	        }
	    	    }
	    	}
        } else {
            isNew = true;
            action = "add";
        }
    } else {
    	for (Object key : request.getParameterMap().keySet()) {
    		String paramName = (String) key;
    		if (paramName.startsWith("prop_")) {
    			if (request.getParameterValues(paramName).length > 1) {
	    			request.setAttribute(paramName, request.getParameterValues(paramName));
    			} else {
	    			request.setAttribute(paramName, request.getParameter(paramName));
    			}
    		}
    	}
    }
//}

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

%>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=<%= response.getCharacterEncoding() %>">
	<title>Repo Resource Manager</title>
	<style>
		.node {
			border-width : 1;
			border-style : solid;
		}
		.subnode {
			border-width : 1;
			border-style : solid;
		}
	</style>
</head>
<body>
	<form method="post" action="resource.jsp" accept-charset="UTF-8">
	<%
	    out.println(
	   		"<table class=node>" +
	   			"<tr>" +
	   				"<td>Parent path</td>" +
	   				"<td>" + parentPath + "/</td>" +
	   			"</tr>");
		Node parentNode = repSession.getRootNode();
		if (parentPath.length() > 0) {
		    parentNode = parentNode.getNode(parentPath);
		}
		String[] defs = getAllowedNodeTypes(parentNode);
		boolean ready = writeNodeFields(out, request, isNew, defs, "prop_");
		out.println(
			"</table>");
		out.println("<input type=\"hidden\" name=\"parentpath\" value=\"" + parentPath + "\">");
		out.println("<input type=\"hidden\" name=\"path\" value=\"" + path + "\">");
		out.println("<input type=\"hidden\" name=\"action\" value=\"" + action + "\">");
		if (!isNew || ready) {
			out.println("<input type=\"submit\" name=\"submitted\" value=\"" + buttonName+ "\">");
		} else {
			out.println("<input type=\"submit\" name=\"continue\" value=\"Continue\">");
		}
	%>
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

private int getValue(String value, int defaultValue) {
    return (value != null) ? Integer.valueOf(value).intValue() : defaultValue;
}

private String value2Str(Value value) throws RepositoryException, ValueFormatException {
    String result;
	result = value.getString();
    return result;
}

private String[] getAllowedNodeTypes(Node parentNode) throws NamingException, RepositoryException {
    HashSet<String> names = new HashSet<String>();
	NodeType type = parentNode.getPrimaryNodeType();
	NodeDefinition[] defs = type.getChildNodeDefinitions();
	for (NodeDefinition def : defs) {
	    addNodeTypeNames(names, def);
	}
	String[] result = names.toArray(new String[names.size()]);
	Arrays.sort(result);
	return result;
}

private String[] nodeTypeNames(NodeDefinition def) throws NamingException, RepositoryException {
    HashSet<String> names = new HashSet<String>();
    addNodeTypeNames(names, def);
	String[] result = names.toArray(new String[names.size()]);
	Arrays.sort(result);
	return result;
}

private void addNodeTypeNames(HashSet<String> names, NodeDefinition def) throws NamingException, RepositoryException {
	NodeTypeIterator iter = getSession().getWorkspace().getNodeTypeManager().getPrimaryNodeTypes();
	while (iter.hasNext()) {
	    NodeType nodeType = iter.nextNodeType();
	    boolean isAssignable = true;
	    for (NodeType nt : def.getRequiredPrimaryTypes()) {
	        isAssignable = isAssignable && nodeType.isNodeType(nt.getName());
	    }
	    if (isAssignable) {
	        if (def.getName().equals("*")) {
	         names.add(nodeType.getName());
	        } else {
	    	    names.add(def.getName() + "[" + nodeType.getName() + "]");
	        }
	    }
	}
}

private NodeType getNodeType(String typeName) throws NamingException, RepositoryException {
	NodeType nodeType = getSession().getWorkspace().getNodeTypeManager().getNodeType(typeName);
	return nodeType;
}

private void writePropertyFields(JspWriter out, HttpServletRequest request, boolean isNew, String primaryNodeType, String varName) throws IOException, NamingException, RepositoryException {
	NodeType nodeType = getNodeType(primaryNodeType);
	PropertyDefinition[] props = nodeType.getPropertyDefinitions();
	for (PropertyDefinition prop : props) {
		if ("jcr:primaryType".equals(prop.getName())) {
			continue;
		}
		if (isNew && prop.isAutoCreated() && prop.isProtected()) {
			continue;
		}
	    out.println("<tr>");
	    if (prop.isMandatory()) {
		    out.println("<td valign=\"top\"><b>" + prop.getName() + "</b></td>");
	    } else {
		    out.println("<td valign=\"top\">" + prop.getName() + "</td>");
	    }
	    out.println("<td>");
	    if (prop.isMultiple()) {
	        int count = getValue((String)request.getAttribute(varName + "count_" + prop.getName()), 0);
		    out.println("<input type=\"hidden\" name=\"" + varName + "count_" + prop.getName() + "\" value=\"" + count + "\">");
		    for (int i = 0; i < count; i++) {
		    	writeField(out, request, prop, varName + "#" + i + "_");
			    out.println("<br>");
		    }
		    out.println("<input type=\"button\" name=\"#add_" + varName + prop.getName() + "\" value=\"+ Property\">");
	    } else {
	    	writeField(out, request, prop, varName);
	    }
	    out.println("</td>");
	    out.println("</tr>");
	}
}

private void writeField(JspWriter out, HttpServletRequest request, PropertyDefinition prop, String varName) throws IOException {
    if (prop.isProtected()) {
	    out.println(getValue((String)request.getAttribute(varName + prop.getName()), ""));
    } else {
	    switch (prop.getRequiredType()) {
	    case PropertyType.BINARY:
		    out.println("<textarea cols=80 rows=20 name=\"" + varName + prop.getName() + "\">" + getValue((String)request.getAttribute(varName + prop.getName()), "") + "</textarea>");
	        break;
	    case PropertyType.BOOLEAN:
	        // TODO: NIY
		    out.println("Not implemented yet");
//		    out.println("<input type=\"text\" name=\"" + prop.getName() + "\" value=\"" + (String)request.getAttribute(prop.getName()) + "\">");
	        break;
	    case PropertyType.DATE:
	    case PropertyType.DOUBLE:
	    case PropertyType.LONG:
	    case PropertyType.NAME:
	    case PropertyType.PATH:
	    case PropertyType.REFERENCE:
	    case PropertyType.STRING:
		    out.println("<input type=\"text\" name=\"" + varName + prop.getName() + "\" value=\"" + getValue((String)request.getAttribute(varName + prop.getName()), "") + "\">");
	        break;
	    case PropertyType.UNDEFINED:
	        // TODO: NIY
		    out.println("Not implemented yet");
	        break;
	    }
	    if (prop.isMultiple()) {
	        // TODO: This is not a proper implementation at all!!
		    out.println("<input type=\"button\" name=\"#delete_" + varName + prop.getName() + "\" value=\"-\">");
	    }
    }
}

private boolean writeNodeTypeSelection(JspWriter out, HttpServletRequest request, String[] defs, String varName, String selection) throws IOException {
    boolean selected = false;
    out.println(
		"<tr>" +
			"<td><b>Primary node type</b></td>" +
			"<td>" +
				"<select name=\"" + varName + "primarynodetype\">");
	for (String def : defs) {
	    if (def.equals(selection)) {
		    out.println("<option selected>" + def + "</option>");
		    selected = true;
	    } else {
		    out.println("<option>" + def + "</option>");
	    }
	}
	out.println(
				"</select>" +
			"</td>" +
		"</tr>");
	return selected;
}

private boolean writeNodeFields(JspWriter out, HttpServletRequest request, boolean isNew, String[] defs, String varName) throws IOException, NamingException, RepositoryException {
    boolean allTypesSelected = false;

    String primaryNodeType = getValue((String)request.getAttribute(varName + "primarynodetype"), "");
    
    // If only one node type definition exists we select it by default
	if ((primaryNodeType.length() == 0) && (defs.length == 1)) {
		primaryNodeType = defs[0];
		request.setAttribute(varName + "primarynodetype", primaryNodeType);
	}
	
    String name;
    String realNodeType;
    boolean fixedName;
    Pattern ex = Pattern.compile("^(.*)\\[(.*)\\]$");
    Matcher m = ex.matcher(primaryNodeType);
    if (m.matches()) {
    	name = primaryNodeType.substring(m.start(1), m.end(1));
    	realNodeType = primaryNodeType.substring(m.start(2), m.end(2));
	    fixedName = true;
    } else {
	    name = getValue((String)request.getAttribute(varName + "name"), "");
	    realNodeType = primaryNodeType;
	    fixedName = false;
    }
    
	if (isNew) {
	    allTypesSelected = writeNodeTypeSelection(out, request, defs, varName, primaryNodeType);
	} else {
	    out.println(
			"<tr>" +
				"<td><b>Primary node type</b></td>" +
				"<td>" + primaryNodeType + "<input type=\"hidden\" name=\"" + varName + "primarynodetype\" value=\"" + primaryNodeType + "\"></td>" +
			"</tr>");
	    allTypesSelected = true;
	}
	
	if (fixedName) {
	    out.println(
			"<tr>" +
				"<td><b>Name</b></td>" +
				"<td>" + name + "<input type=\"hidden\" name=\"" + varName + "name\" value=\"" + name + "\"></td>" +
			"</tr>");
	} else {
	    out.println(
			"<tr>" +
				"<td><b>Name</b></td>" +
				"<td><input type=\"text\" name=\"" + varName + "name\" value=\"" + name + "\"></td>" +
			"</tr>");
	}
    
    if (allTypesSelected) {
	    writePropertyFields(out, request, isNew, realNodeType, varName);
	    
	    if (isNew) {
			NodeType nodeType = getNodeType(realNodeType);
			NodeDefinition[] subdefs = nodeType.getChildNodeDefinitions();
			int cnt = 1;
			for (NodeDefinition def : subdefs) {
			    if (def.isMandatory()) {
				    out.println(
				    	"<tr><td colspan=2 class=subnodecell>" +
					   		"<table class=subnode>");
				    allTypesSelected = allTypesSelected && writeNodeFields(out, request, true, nodeTypeNames(def), varName + cnt + "_");
					out.println(
							"</table>" +
						"</td></tr>");
			    }
			    cnt++;
			}
	    }
    }
    
	return allTypesSelected;
}

private void setNodeProperties(Node node, String varName, HttpServletRequest request) throws RepositoryException {
	NodeType nodeType = node.getPrimaryNodeType();
	PropertyDefinition[] props = nodeType.getPropertyDefinitions();
	for (PropertyDefinition prop : props) {
	    String value = request.getParameter(varName + prop.getName());
	    if (value != null) {
		    if (value.length() > 0) {
	    		node.setProperty(prop.getName(), value);
		    } else {
		        node.setProperty(prop.getName(), (String)null);
		    }
	    }
	}
}

private Node createNode(Node root, String path, String primaryNodeType, String varName, HttpServletRequest request) throws RepositoryException {
	Node node = root.addNode(path, primaryNodeType);
    setNodeProperties(node, varName, request);
    
	NodeType nodeType = node.getPrimaryNodeType();
	NodeDefinition[] subdefs = nodeType.getChildNodeDefinitions();
	int cnt = 1;
	for (NodeDefinition def : subdefs) {
	    if (def.isMandatory()) {
	    	String subVarName = varName + cnt + "_";

	    	String name;
	        String realNodeType;
	    	String typeName = request.getParameter(subVarName + "primarynodetype");
	        Pattern ex = Pattern.compile("^(.*)\\[(.*)\\]$");
	        Matcher m = ex.matcher(typeName);
	        if (m.matches()) {
	        	name = typeName.substring(m.start(1), m.end(1));
	        	realNodeType = typeName.substring(m.start(2), m.end(2));
	        } else {
	    	    name = getValue(request.getParameter(subVarName + "name"), "");
	    	    realNodeType = typeName;
	        }
	        
	    	String subpath = path + "/" + name;
	        
	    	createNode(root, subpath, realNodeType, subVarName, request);
	    }
	    cnt++;
	}

	return node;
}

%>

