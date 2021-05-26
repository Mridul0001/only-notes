enum Filters {
  date,
  length,
  alphabetically
}

enum FilterOrder {
  asc,
  dsc
}

class FilterOptions{
  Filters _filter = Filters.date;
  FilterOrder _order = FilterOrder.dsc;

  Filters getFilter(){
    return this._filter;
  }

  FilterOrder getOrder(){
    return this._order;
  }

  void setFilter(Filters filter){
    this._filter = filter;
  }

  void setOrder(FilterOrder order){
    this._order = order;
  }
}