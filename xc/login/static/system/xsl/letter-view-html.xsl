<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:x="http://ai-and-it.de/xmlns/2020/xc"
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
  xmlns="http://www.w3.org/1999/xhtml"
  version="1.0">

  <xsl:output method="xml" encoding="utf-8"/>

  <xsl:param name="template-doc-uri" select="'/main/getf/templates/html/letter.html'"/>
  <xsl:param name="template-doc" select="document($template-doc-uri)"/>

  <xsl:include href="view-utils.xsl"/>

  <xsl:template match="/">
    <div>
      <xsl:if test="not($template-doc)">
        <div>
          <p>
            <span style="color: red;"> Failed to load template document <xsl:value-of select="$template-doc-uri"/> </span>
          </p>
        </div>
        <xsl:message> Failed to load template document <xsl:value-of select="$template-doc-uri"/>
        </xsl:message>
      </xsl:if>
      <xsl:apply-templates select="$template-doc/*/xhtml:body/*"/>
    </div>
  </xsl:template>

</xsl:stylesheet>
