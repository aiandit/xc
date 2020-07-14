<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
  xmlns="http://www.w3.org/1999/xhtml"
  version="1.0">

  <xsl:output method="xml" encoding="utf-8"/>

  <xsl:template match="*" mode="to-xhtml">
    <xsl:element name="{local-name()}" namespace="http://www.w3.org/1999/xhtml">
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates mode="to-xhtml"/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="*" mode="copy">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates mode="copy"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="*" mode="create-offer">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates mode="create-offer"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="address" mode="create-offer">
    <xsl:apply-templates select="$this/*/cont/*" mode="copy"/>
  </xsl:template>

  <xsl:template match="text()"/>

  <xsl:variable name="template-doc-uri" select="'/main/getf/xml/types/offer.xml'"/>
  <xsl:variable name="template-doc" select="document($template-doc-uri)"/>

  <xsl:variable name="this" select="/"/>

  <xsl:template match="/">
    <div>
      Offer: created:
      <form action="edit" method="post">
        <fieldset>
          <legend>XCerp Create Address</legend>
          <table>
            <tr>
              <th>
                <label for="id-path">Path</label>
              </th>
              <td>
                <input id="id-path" type="text" name="path" value="{/x/cgi/path}"/>
              </td>
            </tr>
            <tr>
              <th>
          <label for="id-data">New Document</label>
              </th>
              <td>
          <textarea id="id-data" name="data">
            <xsl:apply-templates select="$template-doc/*" mode="create-offer"/>
          </textarea>
              </td>
            </tr>
            <tr>
              <td colspan="2">
                <input type="submit"/>
              </td>
            </tr>
          </table>
          <input type="hidden" name="csrfmiddlewaretoken" value="{/x/cgi/csrfmiddlewaretoken}"/>
        </fieldset>
      </form>
    </div>
  </xsl:template>

</xsl:stylesheet>
