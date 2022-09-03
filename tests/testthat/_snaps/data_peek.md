# data_peek snapshots look as expected

    Code
      data_peek(iris)
    Output
      Data frame with 150 rows and 5 columns
      
      Variable     | Type    | Values                                        
      -----------------------------------------------------------------------
      Sepal.Length | numeric | 5.1, 4.9, 4.7, 4.6, 5, 5.4, 4.6, 5, 4.4, ...  
      Sepal.Width  | numeric | 3.5, 3, 3.2, 3.1, 3.6, 3.9, 3.4, 3.4, 2.9, ...
      Petal.Length | numeric | 1.4, 1.4, 1.3, 1.5, 1.4, 1.7, 1.4, 1.5, ...   
      Petal.Width  | numeric | 0.2, 0.2, 0.2, 0.2, 0.2, 0.4, 0.3, 0.2, ...   
      Species      | factor  | setosa, setosa, setosa, setosa, setosa, ...   

---

    Code
      data_peek(iris, n = 3)
    Output
      Data frame with 150 rows and 5 columns
      
      Variable     | Type    | Values                                        
      -----------------------------------------------------------------------
      Sepal.Length | numeric | 5.1, 4.9, 4.7, 4.6, 5, 5.4, 4.6, 5, 4.4, ...  
      Sepal.Width  | numeric | 3.5, 3, 3.2, 3.1, 3.6, 3.9, 3.4, 3.4, 2.9, ...
      Petal.Length | numeric | 1.4, 1.4, 1.3, 1.5, 1.4, 1.7, 1.4, 1.5, ...   

---

    Code
      data_peek(iris, width = 130)
    Output
      Data frame with 150 rows and 5 columns
      
      Variable     | Type    | Values                                                                                                  
      ---------------------------------------------------------------------------------------------------------------------------------
      Sepal.Length | numeric | 5.1, 4.9, 4.7, 4.6, 5, 5.4, 4.6, 5, 4.4, 4.9, 5.4, 4.8, 4.8, 4.3, 5.8, 5.7, 5.4, 5.1, 5.7, 5.1, 5.4, ...
      Sepal.Width  | numeric | 3.5, 3, 3.2, 3.1, 3.6, 3.9, 3.4, 3.4, 2.9, 3.1, 3.7, 3.4, 3, 3, 4, 4.4, 3.9, 3.5, 3.8, 3.8, 3.4, ...    
      Petal.Length | numeric | 1.4, 1.4, 1.3, 1.5, 1.4, 1.7, 1.4, 1.5, 1.4, 1.5, 1.5, 1.6, 1.4, 1.1, 1.2, 1.5, 1.3, 1.4, 1.7, 1.5, ... 
      Petal.Width  | numeric | 0.2, 0.2, 0.2, 0.2, 0.2, 0.4, 0.3, 0.2, 0.2, 0.1, 0.2, 0.2, 0.1, 0.1, 0.2, 0.4, 0.4, 0.3, 0.3, 0.3, ... 
      Species      | factor  | setosa, setosa, setosa, setosa, setosa, setosa, setosa, setosa, setosa, setosa, setosa, setosa, ...     
