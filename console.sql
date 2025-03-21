
CREATE table if not exists award_data
(company_name TEXT,
    Award_Title TEXT,
    Agency TEXT,
    Branch varchar(255),
    Phase varchar(20),
    Program varchar(20),
    Agency_Tracking_Number	Varchar(50),
    Contract Varchar(50),
    Proposal_Award_Date varchar(20),
    Contract_End_Date varchar(20),
 Solicitation_Number varchar(20),
 Solicitation_Year varchar(20),
 Solicitation_Close_Date varchar(20),
 Proposal_Receipt_Date varchar,
 Date_of_Notification varchar,
 Topic_Code	varchar(20),
 Award_Year	varchar(20),
 Award_Amount varchar(20),
 Duns varchar(20),
 HUBZone_Owned char(1),
Socially_and_Economically_Disadvantaged char(1),
 Women_Owned char(1),
 Number_Employees int,
 Company_Website varchar(100),
 Address1 TEXT,
 Address2 TEXT,
 City varchar(50),
 State varchar(2),
 Zip varchar(20),
 Abstract TEXT,
 Contact_Name varchar(255),
 Contact_Title varchar(255),
 Contact_Phone varchar(15),
 Contact_Email varchar(50),
 PI_Name varchar(255),
 PI_Title varchar(255),
 PI_Phone varchar(15),
 PI_Email varchar(50),
 RI_Name varchar(255),
 RI_POC_Name varchar(255),
 RI_POC_Phone varchar(15)
);

CREATE TABLE nih_proj (
    APPLICATION_ID INTEGER PRIMARY KEY,
    ACTIVITY VARCHAR(10),
    ADMINISTERING_IC VARCHAR(10),
    APPLICATION_TYPE INT,
    ARRA_FUNDED CHAR(1),
    AWARD_NOTICE_DATE DATE,
    BUDGET_START DATE,
    BUDGET_END DATE,
    CFDA_CODE INTEGER,
    CORE_PROJECT_NUM VARCHAR(50),
    ED_INST_TYPE VARCHAR(255),
    OPPORTUNITY_NUMBER VARCHAR(255),
    FULL_PROJECT_NUM VARCHAR(50),
    FUNDING_ICs VARCHAR(255),
    FUNDING_MECHANISM VARCHAR(50),
    FY INTEGER,
    IC_NAME VARCHAR(255),
    NIH_SPENDING_CATS VARCHAR(255),
    ORG_CITY VARCHAR(255),
    ORG_COUNTRY VARCHAR(255),
    ORG_DEPT VARCHAR(255),
    ORG_DISTRICT INTEGER,
    ORG_DUNS varchar(30),
    ORG_FIPS VARCHAR(10),
    ORG_IPF_CODE INTEGER,
    ORG_NAME VARCHAR(255),
    ORG_STATE VARCHAR(10),
    ORG_ZIPCODE VARCHAR(20),
    PHR TEXT,
    PI_IDS TEXT,
    PI_NAMEs TEXT,
    PROGRAM_OFFICER_NAME VARCHAR(255),
    PROJECT_START DATE,
    PROJECT_END DATE,
    PROJECT_TERMS TEXT,
    PROJECT_TITLE TEXT,
    SERIAL_NUMBER INTEGER,
    STUDY_SECTION VARCHAR(50),
    STUDY_SECTION_NAME VARCHAR(255),
    SUBPROJECT_ID VARCHAR(255),
    SUFFIX VARCHAR(255),
    SUPPORT_YEAR INTEGER,
    DIRECT_COST_AMT INTEGER,
    INDIRECT_COST_AMT INTEGER,
    TOTAL_COST INTEGER,
    TOTAL_COST_SUB_PROJECT INTEGER
);




SELECT * FROM "award_data" LIMIT 10;

SELECT * FROM "nih_proj" LIMIT 10;

SELECT
    LOWER(sb.company) AS company_name,
    COUNT(sb.company) AS sbir_awards,
    COUNT(nih.ORG_NAME) AS nih_funding_records
FROM award_data sb
JOIN nih_proj nih
    ON LOWER(sb.company) = LOWER(nih.ORG_NAME) -- Case-insensitive match
GROUP BY LOWER(sb.company)
ORDER BY company_name;

SELECT
    company,
    SUM(CAST(Award_Amount AS NUMERIC)) AS total_award
FROM award_data
WHERE Award_Amount ~ '^[0-9]+(\.[0-9]*)?$' -- Ensures only numeric values are considered
GROUP BY company
HAVING SUM(CAST(Award_Amount AS NUMERIC)) >
       (SELECT AVG(total_award)
        FROM (SELECT company, SUM(CAST(Award_Amount AS NUMERIC)) AS total_award
              FROM award_data
              WHERE Award_Amount ~ '^[0-9]+(\.[0-9]*)?$'
              GROUP BY company) subquery)
ORDER BY total_award DESC;

SELECT
    APPLICATION_ID,
    COALESCE((LENGTH(LOWER(PHR)) - LENGTH(REPLACE(LOWER(PHR), 'the', ''))) / LENGTH('the'), -1) AS the_count
FROM nih_proj
ORDER BY the_count DESC;

SELECT
    PI_NAMEs AS contact_pi,
    COUNT(*) AS occurrence_count
FROM nih_proj
WHERE PI_NAMEs IS NOT NULL AND PI_NAMEs <> ''
GROUP BY PI_NAMEs
ORDER BY occurrence_count DESC, contact_pi ASC;


SELECT DISTINCT City, State FROM award_data
UNION
SELECT DISTINCT ORG_CITY, ORG_STATE FROM nih_proj;

WITH term_counts AS (
    SELECT
        unnest(string_to_array(LOWER(PROJECT_TERMS), ' ')) AS term
    FROM nih_proj
)
SELECT term, COUNT(*) AS occurrence_count
FROM term_counts
GROUP BY term
ORDER BY occurrence_count DESC
LIMIT 1;


CREATE TABLE patents (
    id SERIAL PRIMARY KEY,
    publication_country          VARCHAR(50),
    publication_doc_number       VARCHAR(50),
    publication_kind             VARCHAR(50),
    publication_date             DATE,
    grant_length                 INTEGER,
    application_country          VARCHAR(50),
    application_doc_number       VARCHAR(50),
    application_date             DATE,
    applicant_organization       VARCHAR(255),
    applicant_location           VARCHAR(255),
    organization_residence_country VARCHAR(50),
    assignee_organization        VARCHAR(255),
    assignee_location            VARCHAR(255),
    inventor                     VARCHAR(255),
    inventor_location            VARCHAR(255),
    agent_organization           VARCHAR(255),
    agent_location               VARCHAR(255),
    invention_title              VARCHAR(255),
    primary_examiners            VARCHAR(255),
    assistant_examiners          VARCHAR(255),
    reference_name               VARCHAR(255),
    reference_country            VARCHAR(50),
    reference_categories         VARCHAR(255),
    file_name                    VARCHAR(255)
);

SELECT * FROM "patents" LIMIT 10;
SELECT * FROM "SBIR_awards" LIMIT 10;

SELECT * FROM "award_data" LIMIT 10;


SELECT
    a.company,
    a.award_title,
    p.applicant_organization,
    p.invention_title
FROM award_data a
JOIN patents p
    ON LOWER(a.award_title) = LOWER(p.invention_title)
    AND LOWER(a.company) = LOWER(p.applicant_organization);

SELECT
    n.org_name,
    n.project_title,
    p.applicant_organization,
    p.invention_title
FROM nih_proj n
JOIN patents p
    ON LOWER(n.project_title) = LOWER(p.invention_title)
    AND LOWER(n.org_name) = LOWER(p.applicant_organization);


--Patents by Publication Country:
SELECT
    publication_country,
    COUNT(*) AS patent_count
FROM patents
GROUP BY publication_country
ORDER BY patent_count DESC;


-- Count companies from SBIR awards:
SELECT company AS company, COUNT(*) AS count
FROM award_data
GROUP BY company
ORDER BY count DESC
LIMIT 10;

-- Count companies from patents:
SELECT applicant_organization AS company, COUNT(*) AS count
FROM patents
GROUP BY applicant_organization
ORDER BY count DESC
LIMIT 10;

-- Count companies from NIH projects:
SELECT org_name AS company, COUNT(*) AS count
FROM nih_proj
GROUP BY org_name
ORDER BY count DESC
LIMIT 10;



-- Prolific inventors in patents:
SELECT inventor, COUNT(*) AS count
FROM patents
GROUP BY inventor
ORDER BY count DESC
LIMIT 10;

-- Prolific contacts in SBIR awards (assuming Contact_Name is used):
SELECT contact_name, COUNT(*) AS count
FROM award_data
GROUP BY contact_name
ORDER BY count DESC
LIMIT 10;

-- Prolific PIs in NIH projects:
SELECT pi_names AS person, COUNT(*) AS count
FROM nih_proj
GROUP BY pi_names
ORDER BY count DESC
LIMIT 10;

--Technological areas awards/patents
SELECT
    reference_categories,
    COUNT(*) AS count
FROM patents
GROUP BY reference_categories
ORDER BY count DESC;



WITH combined_text AS (
    SELECT invention_title AS text_field FROM patents
    UNION ALL
    SELECT award_title FROM award_data
    UNION ALL
    SELECT project_title FROM nih_proj
),
words AS (
    SELECT LOWER(word) AS word
    FROM (
        SELECT regexp_split_to_table(text_field, '\W+') AS word
        FROM combined_text
    ) AS sub
    WHERE word <> ''
)
SELECT word, COUNT(*) AS frequency
FROM words
GROUP BY word
ORDER BY frequency DESC
LIMIT 20;


--Companies Active in Multiple Innovation Arenas
WITH companies AS (
    SELECT LOWER(applicant_organization) AS company
    FROM patents
    WHERE applicant_organization IS NOT NULL
    UNION ALL
    SELECT LOWER(company) AS company
    FROM award_data
    WHERE company IS NOT NULL
    UNION ALL
    SELECT LOWER(org_name) AS company
    FROM nih_proj
    WHERE org_name IS NOT NULL
)
SELECT company, COUNT(*) AS total_records
FROM companies
GROUP BY company
ORDER BY total_records DESC
LIMIT 10;

--Correlating SBIR Awards and Patents by Company
SELECT
    LOWER(a.company) AS company,
    COUNT(DISTINCT a.award_title) AS award_count,
    COUNT(DISTINCT p.invention_title) AS patent_count
FROM award_data a
JOIN patents p
    ON LOWER(a.company) = LOWER(p.applicant_organization)
GROUP BY LOWER(a.company)
ORDER BY award_count DESC, patent_count DESC
LIMIT 10;



--Temporal Trends in Innovation
SELECT
    EXTRACT(YEAR FROM publication_date) AS pub_year,
    COUNT(*) AS patent_count
FROM patents
WHERE publication_date IS NOT NULL
GROUP BY pub_year
ORDER BY pub_year;


SELECT
    EXTRACT(YEAR FROM award_notice_date) AS award_year,
    COUNT(*) AS nih_award_count
FROM nih_proj
WHERE award_notice_date IS NOT NULL
GROUP BY award_year
ORDER BY award_year;

--Innovation Footprint by Company Across All Sources
WITH patent_companies AS (
    SELECT LOWER(applicant_organization) AS company, COUNT(*) AS patent_count
    FROM patents
    WHERE applicant_organization IS NOT NULL
    GROUP BY LOWER(applicant_organization)
),
award_companies AS (
    SELECT LOWER(company) AS company, COUNT(*) AS award_count
    FROM award_data
    WHERE company IS NOT NULL
    GROUP BY LOWER(company)
),
nih_companies AS (
    SELECT LOWER(org_name) AS company, COUNT(*) AS nih_count
    FROM nih_proj
    WHERE org_name IS NOT NULL
    GROUP BY LOWER(org_name)
)
SELECT
    COALESCE(pc.company, ac.company, nc.company) AS company,
    COALESCE(pc.patent_count, 0) AS total_patents,
    COALESCE(ac.award_count, 0) AS total_awards,
    COALESCE(nc.nih_count, 0) AS total_nih_projects,
    COALESCE(pc.patent_count, 0) + COALESCE(ac.award_count, 0) + COALESCE(nc.nih_count, 0) AS total_innovation_events
FROM patent_companies pc
FULL OUTER JOIN award_companies ac ON pc.company = ac.company
FULL OUTER JOIN nih_companies nc ON COALESCE(pc.company, ac.company) = nc.company
ORDER BY total_innovation_events DESC
LIMIT 10;


--Analyzing Project Duration vs. Funding in NIH Projects

SELECT
    full_project_num,
    project_title,
    project_start,
    project_end,
    total_cost,
    (project_end - project_start) AS project_duration
FROM nih_proj
WHERE project_start IS NOT NULL AND project_end IS NOT NULL
ORDER BY project_duration DESC
LIMIT 10;




WITH combined_text AS (
    SELECT invention_title AS text_field FROM patents
    UNION ALL
    SELECT award_title FROM award_data
    UNION ALL
    SELECT project_title FROM nih_proj
),
words AS (
    SELECT LOWER(word) AS word
    FROM (
        SELECT regexp_split_to_table(text_field, '\W+') AS word
        FROM combined_text
    ) AS sub
    WHERE word <> ''
)
SELECT word, COUNT(*) AS frequency
FROM words
GROUP BY word
ORDER BY frequency DESC
LIMIT 20;

--patent/SBIR/NIH records have the same authors or companies?
WITH combined_companies AS (
    SELECT
        'patents' AS source,
        id::text AS record_id,
        LOWER(applicant_organization) AS company,
        invention_title AS title
    FROM patents
    WHERE applicant_organization IS NOT NULL AND applicant_organization <> ''

    UNION ALL

    SELECT
        'award_data' AS source,
        md5(award_title || company) AS record_id,  -- using a hash to generate a unique id for awards
        LOWER(company) AS company,
        award_title AS title
    FROM award_data
    WHERE company IS NOT NULL AND company <> ''

    UNION ALL

    SELECT
        'nih_proj' AS source,
        APPLICATION_ID::text AS record_id,
        LOWER(org_name) AS company,
        project_title AS title
    FROM nih_proj
    WHERE org_name IS NOT NULL AND org_name <> ''
)
SELECT
    company,
    COUNT(*) AS record_count,
    json_agg(json_build_object('source', source, 'record_id', record_id, 'title', title)) AS records
FROM combined_companies
GROUP BY company
HAVING COUNT(*) > 1
ORDER BY record_count DESC, company;


WITH combined_people AS (
    SELECT inventor AS person_name, 'patents' AS source, publication_doc_number AS record_id
    FROM patents
    WHERE inventor IS NOT NULL AND TRIM(inventor) <> ''

    UNION ALL

    SELECT contact_name AS person_name, 'award_data' AS source, Agency_Tracking_Number AS record_id
    FROM award_data
    WHERE contact_name IS NOT NULL AND TRIM(contact_name) <> ''

    UNION ALL

    SELECT PI_NAMEs AS person_name, 'nih_proj' AS source, APPLICATION_ID::TEXT AS record_id
    FROM nih_proj
    WHERE PI_NAMEs IS NOT NULL AND TRIM(PI_NAMEs) <> ''
)

SELECT person_name, COUNT(*) AS record_count,
       JSON_AGG(JSON_BUILD_OBJECT('source', source, 'record_id', record_id)) AS records
FROM combined_people
GROUP BY person_name
HAVING TRIM(person_name) <> ''
ORDER BY record_count DESC;


WITH combined_people AS (
    SELECT unnest(string_to_array(inventor, ', ')) AS person_name, 'patents' AS source, publication_doc_number AS record_id
    FROM patents
    WHERE inventor IS NOT NULL AND TRIM(inventor) <> ''

    UNION ALL

    SELECT unnest(string_to_array(contact_name, ', ')) AS person_name, 'award_data' AS source, Agency_Tracking_Number AS record_id
    FROM award_data
    WHERE contact_name IS NOT NULL AND TRIM(contact_name) <> ''

    UNION ALL

    SELECT unnest(string_to_array(PI_NAMEs, ', ')) AS person_name, 'nih_proj' AS source, APPLICATION_ID::TEXT AS record_id
    FROM nih_proj
    WHERE PI_NAMEs IS NOT NULL AND TRIM(PI_NAMEs) <> ''
)

SELECT person_name, COUNT(DISTINCT source) AS dataset_count,
       JSON_AGG(JSON_BUILD_OBJECT('source', source, 'record_id', record_id)) AS records
FROM (
    SELECT DISTINCT person_name, source, record_id FROM combined_people
) subquery
GROUP BY person_name
HAVING COUNT(DISTINCT source) > 1
ORDER BY RANDOM();  -- Ensures we aren't stuck on alphabetized results












