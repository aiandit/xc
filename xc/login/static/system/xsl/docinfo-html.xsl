<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:x="http://ai-and-it.de/xmlns/2020/xc"
                xmlns:xhtml="http://www.w3.org/1999/xhtml"
                xmlns="http://ai-and-it.de/xmlns/2020/xc"
                version="1.0">

  <xsl:output method="xml" encoding="utf-8"/>

  <xsl:include href="view-utils.xsl"/>

  <xsl:template match="x:docinfo">
    <div class="docinfo">
      <h4 class="oc-head">Document Info</h4>
      <div class="oc-body">
        <table>
          <xsl:for-each select="x:*">
            <tr>
              <td>
                <xsl:value-of select="name()"/>
              </td>
              <td>
                <xsl:value-of select="."/>
              </td>
            </tr>
          </xsl:for-each>
        </table>
      </div>
    </div>
  </xsl:template>

</xsl:stylesheet>
