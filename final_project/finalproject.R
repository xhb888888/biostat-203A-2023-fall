library(dplyr)
library(glmnet)
library(ggplot2)
library(pROC)
library(tidyr)
library(gplots)
library(precrec)
library(pROC)

setwd("Desktop/UCLA_courses/Biostat203A/finalproject")

file_path="austismData.txt"
df <- read.table(file_path, sep = "\t", header = TRUE, skip = 1, stringsAsFactors = FALSE)

file_path_status="sample.status.txt"
lines <- readLines(file_path_status)
feature_list <- list()
for (line in lines) {
  # Split the line into entries
  entries <- strsplit(line, "\t")[[1]]
  
  # Use the first entry as the feature name
  feature_name <- entries[1]
  
  # Store the remaining entries under the feature
  feature_values <- entries[-1]
  feature_values <- gsub("\"", "", feature_values)
  # Create or append to the list element for the feature
  feature_list[[feature_name]] <- feature_values
}
#print(feature_list)
unique_values <- unlist(feature_list)
unique_values <- gsub("\"", "", unique_values)

# Count occurrences of each unique value
value_counts <- table(unique_values)


transposed_df <- t(df)
colnames(transposed_df) <- transposed_df[1, ]
transposed_df <- transposed_df[-1, ]

transposed_matrix <- as.matrix(transposed_df)

# Convert entries to numeric
transposed_matrix <- apply(transposed_matrix, 2, as.numeric)

# Convert back to data frame
transposed_df <- as.data.frame(transposed_matrix)


status = unname(feature_list[[1]])
transposed_df$status=status
transposed_df$status[transposed_df$status == "sample type: control (ctrlMO)"] <- 0
transposed_df$status[transposed_df$status == "sample type: healthy women who had children with ASD (asdMO)"] <- 1
transposed_df$status[transposed_df$status == "sample type: ASD"] <- 2
transposed_df$status[transposed_df$status == "sample type: control"] <- 3

# We mainly focus on 0 and 1
df = transposed_df[transposed_df$status == 0 | transposed_df$status ==1,]

df$status=as.numeric(df$status)

# Extract indices of rows where status is 0 and 1
status_0_indices <- which(df$status == 0)
status_1_indices <- which(df$status == 1)

# Extract 4 observations where status is 0 and 4 observations where status is 1
status_0_data <- df[status_0_indices[1:6], ]
status_1_data <- df[status_1_indices[1:6], ]

# Combine both subsets into a test set dataframe
test_set <- rbind(status_0_data, status_1_data)

# Get the indices of rows used in the test set
test_indices <- c(status_0_indices[1:6], status_1_indices[1:6])

# Exclude test set indices to get the training set
train_set <- df[-test_indices, ]

response_var <- train_set$status
predictors <- train_set[, -which(names(train_set) == "status")]

# Standardize predictors 
x <- as.matrix(predictors)


##LASSO Analysis
set.seed(123)
CV = cv.glmnet(x=x,y=response_var,family='binomial',type.measure='class',alpha=0.91,nlambda=100)
plot(CV)
fit = glmnet(x=x,y=response_var,family='binomial',type.measure='class',alpha=0.91,lambda=CV$lambda.1se)
fit$beta[, 1][fit$beta[, 1] != 0]
feature_selected=names(fit$beta[, 1][fit$beta[, 1] != 0])
#testset
response_var_test <- test_set$status
predictors_test <- test_set[, -which(names(test_set) == "status")]
# Standardize predictors 
x_test <- as.matrix(predictors_test)

preds <- predict(fit, newx = x_test, type = 'response',s="lambda.min")

preds_numeric <- as.numeric(preds)  # Convert to numeric
preds
# Convert response_var_test to numeric 
response_numeric <- as.numeric(response_var_test)  # Convert to numeric
# Calculate AUC
auc_score <- roc(response_numeric,preds_numeric,conf.level = 0.95)

# Signifcant Ribosomal Genes referenced to Kuwano's work "https://pubmed.ncbi.nlm.nih.gov/21935445/"

# Reading in Selected Gene labels
gene_label_path <- "GPL6480-tbl-1.txt"

# Read the data into a dataframe
col_names <- c("ID", "SPOT_ID", "CONTROL_TYPE", "REFSEQ", "GB_ACC", "GENE", "GENE_SYMBOL", "GENE_NAME", 
               "UNIGENE_ID", "ENSEMBL_ID", "TIGR_ID", "ACCESSION_STRING", "CHROMOSOMAL_LOCATION", "CYTOBAND", 
               "DESCRIPTION", "GO_ID", "SEQUENCE")

lines <- readLines(gene_label_path)
ribosomal=c("RPL7", "RPL26", "RPL31", "RPL34", "RPL39", "RPL41", "RPL9", "RPS17", "RPS27L")

# Initialize an empty list to store feature information
feature_info_list_Lasso <- list()
feature_info_list_ribosomal <- list()
# Process each line
for (line in lines) {
  # Split the line by tabs
  fields <- unlist(strsplit(line, "\t"))
  
  # Check if the line has the expected number of fields
  if (length(fields) == length(col_names)) {
    # Extract information from the first entry
    feature_id <- fields[1]
    gene <- fields[7]
    # Check if the feature_id is in the list of features
    if (feature_id %in% feature_selected) {
      # Append the relevant information to the feature_info_list
      feature_info_list_Lasso <- append(feature_info_list_Lasso, list(fields))
    }
    if (gene %in% ribosomal){
      feature_info_list_ribosomal <- append(feature_info_list_ribosomal, list(fields))
    }
  } else {
    # Print a warning if the line doesn't have the expected number of fields
    warning("Line has unexpected number of fields:", line)
  }
}

df_feature_info_Lasso <- do.call(rbind, feature_info_list_Lasso)
df_feature_info_ribosomal <- do.call(rbind, feature_info_list_ribosomal)
# Set column names
colnames(df_feature_info_Lasso) <- col_names
colnames(df_feature_info_ribosomal) <- col_names

selected_columns <- c("ID", "GENE_SYMBOL", "GENE_NAME", "CHROMOSOMAL_LOCATION")
gene_selected_Lasso <- df_feature_info_Lasso[, selected_columns]
gene_selected_ribosomal <- df_feature_info_ribosomal[, selected_columns]

df_gene_selected_Lasso <- as.data.frame(gene_selected_Lasso)
df_gene_selected_ribosomal <- as.data.frame(gene_selected_ribosomal)

missing_columns <- df_gene_selected_ribosomal$ID[!(df_gene_selected_ribosomal$ID %in% colnames(df))]
rows_to_remove <- which(df_gene_selected_ribosomal$ID %in% missing_columns)
# Remove rows
cleaned_df_gene_selected_ribosomal <- df_gene_selected_ribosomal[-rows_to_remove, ]
# Print the cleaned dataframe
print(cleaned_df_gene_selected_ribosomal)
#Since there are repetition of genes, we only keep the first appeared observation for each gene
unique_df_ribosomal <- cleaned_df_gene_selected_ribosomal %>%
  group_by(GENE_SYMBOL) %>%
  slice(1) %>%
  ungroup()

# View the resulting dataframe
unique_df_ribosomal <- as.data.frame(unique_df_ribosomal)

gene_lasso = feature_selected
gene_ribosomal = unique_df_ribosomal$ID

#check common Genes
if (any(gene_lasso %in% gene_ribosomal)) {
  print("There is at least one common string.")
} else {
  print("There are no common strings.")
}

#Check variance here for assumption of two sample t-test test
for (feature in gene_lasso){
  group0=df[df$status == 0, feature]
  group1=df[df$status == 1, feature]
  variance=max(var(group0), var(group1)) / min(var(group0), var(group1))
  if (variance>3){
    print(feature)
  }
}
for (feature in gene_ribosomal){
  group0=df[df$status == 0, feature]
  group1=df[df$status == 1, feature]
  variance=max(var(group0), var(group1)) / min(var(group0), var(group1))
  if (variance>3){
    print(feature)
  }
}

#From above result, we can see 8 genes have unequal variance since the sample variance ratio is above 3
#Two sample t-test with unequal variance is conducted

checkp = function(feature_selected){
  results <- data.frame(feature = character(), p_value = numeric(), ci_lower = numeric(), ci_upper = numeric(), stringsAsFactors = FALSE)
  
  for (feature in feature_selected){
    group0 <- df[df$status == 0, feature]
    group1 <- df[df$status == 1, feature]
    
    t_test_result <- t.test(group0, group1,var.equal = FALSE)
    
    # Extracting p-value and confidence interval
    p_value <- t_test_result$p.value
    ci_lower <- t_test_result$conf.int[1]
    ci_upper <- t_test_result$conf.int[2]
    
    # Adding results to the dataframe
    results <- rbind(results, data.frame(feature = feature, p_value = p_value, ci_lower = ci_lower, ci_upper = ci_upper))
  }
  
  return(results)
}

# Example usage
result_table <- checkp(gene_lasso)
result_table_2 <- checkp(gene_ribosomal)

# Merge df_gene_selected_Lasso with result_table
merged_df_lasso <- merge(gene_selected_Lasso, result_table, by.x = "ID", by.y = "feature", all.x = TRUE)

# Merge df_gene_selected_IPA with result_table_2
merged_df_ribosomal <- merge(unique_df_ribosomal, result_table_2, by.x = "ID", by.y = "feature", all.x = TRUE)

#Tabel 1
merged_df_lasso
merged_df_ribosomal


#Figure 1 and Figure 2

df_long_lasso <- gather(df, key = "Gene", value = "Value", all_of(gene_lasso))

# Creating a boxplot with facets for each 'y' variable
ggplot(df_long_lasso, aes(x = as.factor(status), y = Value)) +
  geom_boxplot(outlier.colour = "red", outlier.shape = 1, outlier.size = 4) +
  labs(title = "Panel for Selected Genes",
       x = "Group(0=ctrlMO,1=asdMO)",
       y = "Expression") +
  facet_wrap(~ Gene, scales = "free", nrow=3,ncol = 3) +
  scale_x_discrete(labels = c("0", "1")) +  # Replace with appropriate labels for 'status'
  scale_y_continuous(labels = scales::comma) 

df_long_ribosomal <- gather(df, key = "Gene", value = "Value", all_of(gene_ribosomal))

ggplot(df_long_ribosomal, aes(x = as.factor(status), y = Value)) +
  geom_boxplot(outlier.colour = "red", outlier.shape = 1, outlier.size = 4) +
  labs(title = "Panel for Selected Genes",
       x = "Group(0=ctrlMO,1=asdMO)",
       y = "Expression") +
  facet_wrap(~ Gene, scales = "free", nrow=3,ncol = 3) +
  scale_x_discrete(labels = c("0", "1")) +  # Replace with appropriate labels for 'status'
  scale_y_continuous(labels = scales::comma) 


#Regression Analysis
df2 <- df[,c('status',merged_df_ribosomal$ID)]

status_0_indices_2 <- which(df2$status == 0)
status_1_indices_2 <- which(df2$status == 1)

# Extract 6 observations where status is 0 and 6 observations where status is 1
status_0_data_2 <- df2[status_0_indices_2[1:6], ]
status_1_data_2 <- df2[status_1_indices_2[1:6], ]

# Combine both subsets into a test set dataframe
test_set_2 <- rbind(status_0_data_2, status_1_data_2)

# Get the indices of rows used in the test set
test_indices_2 <- c(status_0_indices_2[1:6], status_1_indices_2[1:6])

# Exclude test set indices to get the training set
train_set_2 <- df2[-test_indices_2, ]

# Create formula for logistic regression
#formula <- as.formula("status ~ A_32_P115130 + A_23_P144497 + A_32_P220307 + A_23_P216108 + 
#                        A_23_P135084 + A_23_P77971 + A_23_P206733 + A_23_P87879 + A_23_P212954")
formula <- as.formula(paste("status ~", paste(unique_df_ribosomal$ID, collapse = " + ")))

# Fit logistic regression model
model2 <- glm(formula, data = train_set_2, family = binomial)

# Make predictions on test set
glm_predictions <- predict(model2, newdata = test_set_2, type = "response")
# Convert response_var_test to numeric 
response_numeric_2 <- as.numeric(test_set_2$status)  # Convert to numeric

# Calculate AUC
auc_score_2 <- roc(response_numeric_2, glm_predictions, conf.level = 0.95)
auc_score_2

#Figure 3
plot(auc_score, col = "blue", type = "l", lty = 1, main = "ROC Curve Comparison", xlab = "False Positive Rate", ylab = "True Positive Rate", ylim = c(0, 1))
lines(auc_score_2, col = "red", type = "l", lty = 2)
legend("bottomright", legend = c("Lasso", "Ribosomal"), col = c("blue", "red"), lty = 1:2)



write.csv(df, "ASD_expression_all.csv", row.names = TRUE)
write.csv(test_set, "testing_set_LASSO.csv", row.names = FALSE)
write.csv(train_set, "training_set_LASSO.csv", row.names = FALSE)
write.csv(test_set_2, "testing_set_ribosomal.csv", row.names = FALSE)
write.csv(train_set_2, "training_set_ribosomal.csv", row.names = FALSE)

