<?xml version = "1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <!-- transforms OBO XML format to an XML format that maps directly
       to the GO Database. This transformed XML can be loaded
       directly using the generic DBIx::DBStag module

       see also: go-dev/go-db-perl/scripts/load-go-into-db.pl

       CONSTRAINTS:

       The file to be loaded cannot have trailing IDs

       If an ID from another ontology is referenced, then that
       ontology should also be included in the load

       -->

  <xsl:output indent="yes" method="xml"/>

  <xsl:key name="terms" match="term" use="id"/>
  <xsl:key name="obs-terms-by-name" match="term[is_obsolete]" use="name"/>

  <xsl:template match="/">
    <godb_prestore>
      <dbstag_metadata>
        <map>type/term_synonym.synonym_type_id=term.id</map>
        <map>term1/term2term.term1_id=term.id</map>
        <map>term2/term2term.term2_id=term.id</map>
        <map>type/term2term.relationship_type_id=term.id</map>
        <map>type/gene_product.type_id=term.id</map>
        <map>source_db/association.source_db_id=db.id</map>
        <map>type/synonym.type_id=term.id</map>
        <map>parentfk:term2term.term2_id</map>
      </dbstag_metadata>
      <xsl:apply-templates select="*/source"/>

      <term>
        <acc>all</acc>
        <name>all</name>
        <is_root>1</is_root>
        <term_type>universal</term_type>
        <term_definition>
          <term_definition>
            This term is the most general term possible
          </term_definition>
        </term_definition>
      </term>
      <term>
        <acc>is_a</acc>
        <name>is_a</name>
        <term_type>relationship</term_type>
        <term_definition>
          <term_definition>
            inheritance relationship
          </term_definition>
        </term_definition>
      </term>

      <!-- load relationships before terms -->
      <xsl:apply-templates select="*/typedef"/>
      <xsl:apply-templates select="*/term"/>
      <xsl:apply-templates select="*/term/is_a"/>
      <xsl:apply-templates select="*/typedef/is_a"/>
      <xsl:apply-templates select="*/term/relationship"/>
      <xsl:apply-templates select="assocs/dbset/prod"/>
    </godb_prestore>
  </xsl:template>

  <xsl:template match="source">
    <source_audit>
      <xsl:copy-of select="./*"/>
    </source_audit>
  </xsl:template>

  <xsl:template match="term">
    <term>
      <acc>
        <xsl:value-of select="id"/>
      </acc>
      <xsl:if test="name">
        <name>
          <xsl:value-of select="name"/>
        </name>
      </xsl:if>
      <xsl:if test="namespace">
        <term_type>
          <xsl:value-of select="namespace"/>
        </term_type>
      </xsl:if>
      <xsl:choose>
        <xsl:when test="is_obsolete">
          <is_obsolete>1</is_obsolete>
          <!-- add extra parentage for obsolete terms -->
          <term2term>
            <type>
              <term>
                <acc>is_a</acc>
              </term>
            </type>
            <term1>
              <term>
                <name>
                  <xsl:text>obsolete_</xsl:text>
                  <xsl:value-of select="namespace"/>
                </name>
                <acc>
                  <xsl:text>obsolete_</xsl:text>
                  <xsl:value-of select="namespace"/>
                </acc>
                <term_type>
                  <xsl:value-of select="namespace"/>
                </term_type>
                <is_obsolete>1</is_obsolete>
                <is_root>1</is_root>
              </term>
            </term1>
          </term2term>
        </xsl:when>
        <xsl:otherwise>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:if test="is_root">
        <is_root>1</is_root>
      </xsl:if>
      <xsl:apply-templates select="def"/>
      <xsl:apply-templates select="synonym"/>
      <xsl:apply-templates select="alt_id"/>
      <xsl:apply-templates select="xref_analog"/>
    </term>
  </xsl:template>

  <xsl:template match="typedef">
    <term>
      <acc>
        <xsl:value-of select="id"/>
      </acc>
      <name>
        <xsl:value-of select="translate(name,' ','_')"/>
      </name>
      <term_type>
        <xsl:choose>
          <xsl:when test="namespace">
            <xsl:value-of select="namespace"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>relationship</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </term_type>
      <xsl:if test="is_obsolete">
        <is_obsolete>1</is_obsolete>
      </xsl:if>
      <xsl:apply-templates select="def"/>
      <xsl:apply-templates select="synonym"/>
      <xsl:apply-templates select="alt_id"/>
      <xsl:apply-templates select="xref_analog"/>
    </term>
  </xsl:template>

  <xsl:template match="*" mode="dbxref">
    <dbxref>
      <xref_dbname>
        <xsl:value-of select="substring-before(.,':')"/>    
      </xref_dbname>
      <xref_key>
        <xsl:value-of select="substring-after(.,':')"/>    
      </xref_key>
    </dbxref>
  </xsl:template>

  <xsl:template match="is_a">
    <term2term>
      <type>
        <term>
          <acc>is_a</acc>
        </term>
      </type>
      <!-- term1 is the parent/object/target -->
      <term1>
        <term>
          <acc>
            <xsl:value-of select="."/>
          </acc>
        </term>
      </term1>
      <!-- term2 is the child/subject/current -->
      <term2>
        <term>
          <acc>
            <xsl:value-of select="../id"/>
          </acc>
        </term>
      </term2>
      <xsl:if test = "@completes='true'">
        <completes>1</completes>
      </xsl:if>
    </term2term>
  </xsl:template>

  <xsl:template match="relationship">
    <term2term>
      <type>
        <term>
          <term_type>relationship</term_type>
          <name>
            <xsl:value-of select="type"/>
          </name>
          <acc>
            <xsl:value-of select="type"/>
          </acc>
        </term>
      </type>
      <term1>
        <term>
          <acc>
            <xsl:value-of select="to"/>
          </acc>
        </term>
      </term1>
      <term2>
        <term>
          <acc>
            <xsl:value-of select="../id"/>
          </acc>
        </term>
      </term2>
      <xsl:if test = "@completes='true'">
        <completes>1</completes>
      </xsl:if>
    </term2term>
  </xsl:template>

  <xsl:template match="synonym">
    <term_synonym>
      <term_synonym>
        <xsl:value-of select="synonym_text"/>
      </term_synonym>
      <xsl:if test="@scope != ''">
        <type>
          <term>
            <term_type>synonym_type</term_type>
            <name>
              <xsl:value-of select="@scope"/>
            </name>
            <acc>
              <xsl:value-of select="@scope"/>
            </acc>
          </term>
        </type>
      </xsl:if>
    </term_synonym>
  </xsl:template>
    
  <xsl:template match="alt_id">
    <term_synonym>
      <term_synonym>
        <xsl:value-of select="."/>
      </term_synonym>
      <acc_synonym>
        <xsl:value-of select="."/>
      </acc_synonym>
      <type>
        <term>
          <term_type>synonym_type</term_type>
          <name>
            alt_id
          </name>
          <acc>
            alt_id
          </acc>
        </term>
      </type>
    </term_synonym>
  </xsl:template>
    
  <xsl:template match="xref_analog">
    <term_dbxref>
      <dbxref>
        <xref_dbname>
          <xsl:value-of select="dbname"/>
        </xref_dbname>
        <xref_key>
          <xsl:value-of select="acc"/>
        </xref_key>
      </dbxref>
      <is_for_definition>0</is_for_definition>
    </term_dbxref>
  </xsl:template>
    
  <xsl:template match="dbxref" mode="is_for_definition">
    <term_dbxref>
      <dbxref>
        <xref_dbname>
          <xsl:value-of select="dbname"/>
        </xref_dbname>
        <xref_key>
          <xsl:value-of select="acc"/>
        </xref_key>
      </dbxref>
      <is_for_definition>1</is_for_definition>
    </term_dbxref>
  </xsl:template>
    
  <xsl:template match="def">
    <term_definition>
      <term_definition>
        <xsl:value-of select="defstr"/>
      </term_definition>
      <!-- comment can appear in one of two places -->
      <xsl:if test="../comment">
        <term_comment>
          <xsl:value-of select="../comment"/>          
        </term_comment>
      </xsl:if>
      <xsl:if test="comment">
        <term_comment>
          <xsl:value-of select="comment"/>          
        </term_comment>
      </xsl:if>
    </term_definition>
    <xsl:apply-templates select="dbxref" mode="is_for_definition"/>
  </xsl:template>

  <xsl:template match="prod">
    <gene_product>
      <dbxref>
        <xref_dbname>
          <xsl:value-of select="../proddb"/>
        </xref_dbname>
        <xref_key>
          <xsl:value-of select="prodacc"/>
        </xref_key>
      </dbxref>
      <symbol>
        <xsl:value-of select="prodsymbol"/>
      </symbol>
      <full_name>
        <xsl:value-of select="prodname"/>
      </full_name>
      <type>
        <term>
          <term_type>sequence</term_type>
          <name>
            <xsl:value-of select="prodtype"/>
          </name>
          <acc>
            <xsl:value-of select="prodtype"/>
          </acc>
        </term>
      </type>
      <species>
        <ncbi_taxa_id>
          <xsl:value-of select="prodtaxa"/>
        </ncbi_taxa_id>
      </species>
      <xsl:if test="secondary_prodtaxa">
        <secondary_species>
          <ncbi_taxa_id>
            <xsl:value-of select="secondary_prodtaxa"/>
          </ncbi_taxa_id>
        </secondary_species>
      </xsl:if>
      <xsl:apply-templates select="assoc"/>
      <xsl:apply-templates select="prodsyn"/>
    </gene_product>
  </xsl:template>

  <xsl:template match="prodsyn">
    <gene_product_synonym>
      <product_synonym>
        <xsl:value-of select="."/>
      </product_synonym>
    </gene_product_synonym>
  </xsl:template>

  <xsl:template match="assoc">
    <association>
      <term>
        <acc>
          <xsl:value-of select="termacc"/>
        </acc>
      </term>
      <xsl:if test="is_not">
        <is_not>
          <xsl:value-of select="is_not"/>
        </is_not>
      </xsl:if>
      <xsl:apply-templates select="qualifier"/>
      <xsl:apply-templates select="evidence"/>
      <assocdate>
        <xsl:value-of select="assocdate"/>
      </assocdate>
      <xsl:if test="source_db">
        <source_db>
          <db>
            <name>
              <xsl:value-of select="source_db"/>
            </name>
          </db>
        </source_db>
      </xsl:if>
    </association>
  </xsl:template>

  <xsl:template match="qualifier">
    <association_qualifier>
      <term>
        <acc>
          <xsl:value-of select="."/>
        </acc>
        <name>
          <xsl:value-of select="."/>
        </name>
        <term_type>association_qualifier</term_type>
      </term>
    </association_qualifier>
  </xsl:template>

  <xsl:template match="evidence">
    <evidence>
      <code>
        <xsl:value-of select="evcode"/>
      </code>
      <seq_acc>
        <xsl:value-of select="with"/>
      </seq_acc>
      <xsl:apply-templates select="ref" mode="dbxref"/>
      <xsl:apply-templates select="with"/>
    </evidence>
  </xsl:template>

  <xsl:template match="with">
    <evidence_dbxref>
      <xsl:apply-templates select="." mode="dbxref"/>
    </evidence_dbxref>
  </xsl:template>

  <xsl:template match="text()|@*">
  </xsl:template>


</xsl:stylesheet>



