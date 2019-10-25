# library
library(igraph)
library(qgraph)
library(ggraph)
library(GGally)
library(ggnetwork)

data(mtcars)

# data
head(mtcars)

# Make a correlation matrix:
mat=cor(t(mtcars[,c(1,3:6)]))

# Keep only high correlations
mat[mat<0.95]=0

# Make an Igraph object from this matrix:
network=graph_from_adjacency_matrix(mat, weighted=T, mode="undirected", diag=F)
groupnames = as.factor(mtcars$cyl)
#V(network)$groupnames = groupnames


# qgraph
qgraph(mat, groups=groupnames, layout="spring", palette="pastel", theme="TeamFortress")

# ggraph
ggraph(network, layout="nicely") + 
  geom_edge_link(label_colour="gray") + 
  geom_node_point(aes(color=as.factor(groupnames)), size=10) + 
  geom_node_text(aes(label=names(V(network)))) +
  scale_color_brewer(palette = "Set2") +
  theme_graph()

# ggnet2
ggnet2(network, color = groupnames, palette = "Set2", label=TRUE)

# ggnetwork
n = ggnetwork(network)
n$groupnames = gsub("1","A",n$groupnames)
n$groupnames = gsub("2","B",n$groupnames)
n$groupnames = gsub("3","C",n$groupnames)
ggplot(n, aes(x = x, y = y, xend = xend, yend = yend)) +
  geom_edges(color = "gray") +
  geom_nodes(aes(color = groupnames),size = 12) +
  geom_nodetext(aes(label = vertex.names )) +   
  scale_color_brewer(palette = "Set2") +
  theme_blank()




# DENDROGRAMS: https://rpubs.com/gaston/dendrograms

# Bar plots with variance components
univACE.CMD %>%
  dplyr::select(Label, a2, c2, e2) %>%
  gather(VarComp, value, -Label) %>%
  ggplot(., aes(x=Label, y=value, fill=VarComp)) + geom_bar(stat="identity") +
  coord_flip() + ggtitle("Cortical Mean Diffusivity") +
  xlab("Region") + ylab("Percentage of Variance Explained") +
  scale_fill_discrete(name="Variance Component",
                      labels=c("A", "C", "E"))
