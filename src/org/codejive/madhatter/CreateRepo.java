package org.codejive.madhatter;

import java.io.IOException;

import javax.jcr.Repository;
import javax.naming.InitialContext;
import javax.naming.NamingException;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

/**
 * Servlet implementation class for Servlet: CreateRepo
 * 
 * @web.servlet name="CreateRepo" display-name="CreateRepo" description="Just a
 *              test servlet for creating an initial repo"
 * 
 * @web.servlet-mapping url-pattern="/CreateRepo"
 * 
 */
public class CreateRepo extends javax.servlet.http.HttpServlet implements javax.servlet.Servlet {
    /*
     * (non-Java-doc)
     * 
     * @see javax.servlet.http.HttpServlet#HttpServlet()
     */
    public CreateRepo() {
        super();
    }

    /*
     * (non-Java-doc)
     * 
     * @see javax.servlet.http.HttpServlet#doGet(HttpServletRequest request,
     *      HttpServletResponse response)
     */
    protected void doGet(HttpServletRequest request,
            HttpServletResponse response) throws ServletException, IOException {
        try {
            InitialContext context = new InitialContext();
            Repository repository = (Repository) context.lookup("java:comp/env/jcr/repository");
        } catch (NamingException e) {
            throw new ServletException("Could not create initial repository", e);
        }
    }

    /*
     * (non-Java-doc)
     * 
     * @see javax.servlet.http.HttpServlet#doPost(HttpServletRequest request,
     *      HttpServletResponse response)
     */
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        // TODO Auto-generated method stub
    }
}